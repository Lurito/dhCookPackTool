::                                DH 烘焙打包工具   
::
::    本工具被设计用于 Dread Hunger 模组（mod）制作后的快速烘焙和打包。 
::
::                             版权所有 (C) 2023 爱佐
::
::    This program is free software: you can redistribute it and/or modify
::    it under the terms of the GNU Affero General Public License as
::    published by the Free Software Foundation, either version 3 of the
::    License, or (at your option) any later version.
::
::    This program is distributed in the hope that it will be useful,
::    but WITHOUT ANY WARRANTY; without even the implied warranty of
::    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
::    GNU Affero General Public License for more details.
::
::    You should have received a copy of the GNU Affero General Public License
::    along with this program.  If not, see <https://www.gnu.org/licenses/>.
::
::    你也可以在此处阅读 GNU Affero 通用公共许可协议的非正式中文翻译： 
::    https://www.chinasona.org/gnu/agpl-3.0-cn.html
::    请注意，本翻译本仅为帮助中文使用者更好地理解 GNU Affero 通用公共许可 
::    协议，不适用于使用 GNU Affero 通用公共许可协议发布的软件的法律声明。 

@echo off & setlocal

chcp 65001 > nul

:: Call `json-extractor.cmd` to read JSON file to get these paths
for /f "tokens=* delims=" %%a in ('call %~dp0\libs\json-extractor.cmd %~dp0\configs\config.txt ue_program') do set "UE_Program=%%~a"
for /f "tokens=* delims=" %%a in ('call %~dp0\libs\json-extractor.cmd %~dp0\configs\config.txt ue_project') do set "UE_Project=%%~a"

:: Configure default variables
set "script_dir=%~dp0"
set "output_path=_p.pak"
set "encrypt_config="
set "keep_shaders="
set "customize_packing_assets="

:: Read command-line parameters
echo 选项：%*
:args
set PARAM=%~1
set ARG=%~2

if "%ARG:~0,1%" == "-" (
    :: Another param, not an argument
    set "ARG="
)

if "%PARAM%" == "--ue" (
    :: Specified UE program path
    shift
    if not "%ARG%" == "" (
        shift
        set UE_Program=%ARG%
    ) else (
        echo 错误：未指定 UE 程序路径 
        exit /b 1
    )
) else if "%PARAM%" == "--project" (
    :: Specified project path
    shift
    if not "%ARG%" == "" (
        shift
        set UE_Project=%ARG%
    ) else (
        echo 错误：未指定项目路径 
        exit /b 1
    )
) else if "%PARAM%" == "--encrypt" (
    :: Encryption is enabled
    shift
    if not "%ARG%" == "" (
        :: Path of `Crypto.json` is specified
        shift
        set encrypt_config=%ARG%
    ) else (
        set "encrypt_config=%script_dir%\configs\Crypto.json"
    )
) else if "%PARAM%" == "--output" (
    :: Output path of .pak file is specified
    shift
    if not "%ARG%" == "" (
        shift
        set output_path=%ARG%
    ) else (
        echo 错误：未指定输出路径 
        exit /b 1
    )
) else if "%PARAM%" == "--keep-shaders" (
    shift
    set "keep_shaders=1"
) else if "%PARAM%" == "--customize-packing-assets" (
    shift
    set "customize_packing_assetss=1"
) else if "%PARAM%" == "" (
    goto endargs
) else (
    echo 错误：无法识别的选项 %~1 1>&2
    exit /b 1
)
goto args
:endargs

:: Remove the backslashes at the end of paths
if "%UE_Program:~-1%"=="\" set "UE_Program=%UE_Program:~0,-1%"
if "%UE_Project:~-1%"=="\" set "UE_Project=%UE_Project:~0,-1%"

:: Initalize local project
if exist "%script_dir%\project\" (
    rmdir /S /Q "%script_dir%\project\"
)
xcopy /E /Q "%script_dir%\assets\project\" "%script_dir%\project\"
if exist "%script_dir%\configs\DefaultGame.ini" (
    copy "%script_dir%\configs\DefaultGame.ini" "%script_dir%\project\Config\"
) else (
    copy "%UE_Project%\Config\DefaultGame.ini" "%script_dir%\project\Config\"
)

:: Copy UE project to local - Folders "Developers" and "Collections" are not needed
:: `robocopy` needs a lot of arguments to limit its output to STDOUT
robocopy /S /NFL /NDL /NJH /NJS /NC /NS /NP "%UE_Project%\Content" "%script_dir%\project\Content" /XD "Developers" "Collections"

echo;
echo 开始烘焙资产
echo;

:: Cook assets
call "%UE_Program%\Engine\Build\BatchFiles\RunUAT.bat" BuildCookRun ^
    -project="%script_dir%\project\DreadHunger.uproject" ^
    -skipstage -targetplatform=Win64 -ddc=InstalledDerivedDataBackendGraph ^
    -nocompileeditor -installed -nop4 -cook -utf8output

echo;
echo 烘焙完成，开始打包 
echo;

:: Delete shaders to reduce package size, unless the user wants to keep them
if not "%keep_shaders%" == "1" (
    for /r "%script_dir%\project\Saved\Cooked\WindowsNoEditor\DreadHunger\Content\" %%I in (ShaderArchive-*) do del "%%~dpI%%~nxI"
    for /r "%script_dir%\project\Saved\Cooked\WindowsNoEditor\DreadHunger\Content\" %%I in (ShaderAssetInfo-*) do del "%%~dpI%%~nxI"
) else (
    echo;
    echo --keep-shaders 选项开启，将保留共享着色器 
    echo;
)

:: Add cooked `Content` folder to PAK-filelist.txt, unless the user wants to customize it
if not "%customize_packing_assets%" == "1" (
    echo "%script_dir%project\Saved\Cooked\WindowsNoEditor\DreadHunger\Content\*.*" "..\..\..\DreadHunger\Content\*.*" > "%script_dir%\configs\PAK-filelist.txt"
) else (
    echo;
    echo --customize-packing-assets 选项开启，将使用用户自定义的打包列表 
    echo;
)

:: Convert absolute path to relative path
if "%output_path:~1,2%" == ":\" (
    :: Absolute path
    set "output_path=%output_path%"
) else (
    :: Relative path
    set "output_path=%~dp0\%output_path%"
)

:: Pack cooked assets
if "%encrypt_config%" == "" (
    "%UE_Program%\Engine\Binaries\Win64\UnrealPak.exe" "%output_path%" -create="%script_dir%\configs\PAK-filelist.txt" -compress
) else (
    :: Encrypted pak
    "%UE_Program%\Engine\Binaries\Win64\UnrealPak.exe" "%output_path%" -create="%script_dir%\configs\PAK-filelist.txt" -compress -encrypt -encryptindex -cryptokeys=%encrypt_config%
)

:: Delete local .uproject file, avoiding from the local project displayed in UE homepage
del "%script_dir%\project\DreadHunger.uproject"

echo;
echo 操作完毕，按任意键继续...
pause > nul
