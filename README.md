# DH 烘焙打包工具

本工具用于 Dread Hunger 模组（mod）制作后的快速烘焙和打包。制作模组与常规制作游戏的烘焙、打包流程有所不同，往往只需要打包少量资产，而手动进行这些操作可能会相对繁琐。本工具可以让你省去许多繁琐的步骤，只需要几个简单的操作，就能轻松完成快速烘焙和打包。

本工具支持一键式快速烘焙打包、加密打包、自定义打包资产等功能。

本工具不涉及到任何项目资产的增、删、改、查等功能，请在虚幻编辑器中操作资产。

本工具主要使用 batch 脚本编写，因而仅支持 Windows 系统。

制作其他基于虚幻引擎（Unreal Engine）游戏的模组时，也可以参考这一工具。更多信息请见 [作为其他虚幻游戏模组烘焙打包的参考](#作为其他虚幻游戏模组烘焙打包的参考) 一节。

## 使用教程

### 最简单的样例 - 一键烘焙和封包

首先，你需要在主页右上方点击“下载”按钮，将本项目下载到本地，并解压。

在运行工具之前，你需要修改 `config` 目录下的 `config.txt` 文件，告诉工具你的虚幻引擎程序，以及虚幻项目放在哪里。这是一个示例：

``` JSON
{
    "ue_program": "C:\\Program Files\\Epic Games\\UE_4.26",
    "ue_project": "X:\\My Workspace\\Unreal Projects\\DreadHungerSkin"
}
```

其中，`ue_program` 项是你的虚幻引擎（UE）程序路径。这里填写的是默认的 UE 安装路径，如果你的 UE 程序安装在其他位置，你需要修改为对应的值。

`ue_project` 项则要填写你的 UE 工程项目路径。此路径下会有一个 `[工程名].uproject` 文件。

**注意：你或许已经注意到，此文件中的路径分隔符是两个反斜杠（`\\`）。这是 JSON 文件的特性导致的，修改时请遵循这一规则。**

设置完这几个选项后，你就可以直接双击 `cook-and-pack.cmd`，进行一键烘焙和封包了。

### 命令行选项

本工具也提供命令行选项。支持的选项列表如下：

```
--ue <UE 程序路径>          指定本次烘焙打包的 UE 程序路径
--project <项目路径>        指定本次烘焙打包的项目路径
--output <输出路径>         指定本次打包 .pak 文件的输出路径
--encrypt [加密配置文件]    启用资产加密
                            如果指定了配置文件，则会用指定的文件
                            如果未指定配置文件，则会使用 configs\Crypto.json
--keep-shaders              保留共享着色器文件
--customize-packing-assets  自定义需要打包的资产
```

### 指定 UE 程序路径、项目路径和 .pak 文件的输出路径

如果你需要临时使用不同于配置文件中的 UE 程序路径、项目路径和 .pak 文件的输出路径，可以用以下命令：

``` Batch
.\cook-and-pack.cmd --ue <UE 程序路径> --project <项目路径> --output <输出路径>
```

请将 `<UE 程序路径>` `<项目路径>` `<输出路径>` 替换为相应的路径，以下是两个例子：

``` Batch
.\cook-and-pack.cmd --ue "C:\Program Files\Epic Games\UE_4.26" --project "C:\Users\Username\Documents\Unreal Projects\DreadHunger" --output "92262_p.pak"
.\cook-and-pack.cmd --project "D:\My Workspace\AnotherDreadHungerProject" --output "D:\steamapps\common\Dread Hunger\DreadHunger\Content\Paks\~mods"
```

### 启用资产加密

虚幻引擎支持加密保护资产，详见虚幻引擎 [官方文档的相关内容](https://docs.unrealengine.com/4.26/zh-CN/Basics/Projects/Packaging/#%E7%AD%BE%E5%90%8D%E5%92%8C%E5%8A%A0%E5%AF%86)。

要在本工具中启用资产加密，首先你需要一个 `Crypto.json` 文件。你可以使用本项目的 `configs\Crypto.json` 文件，也可以用其他的 `Crypto.json` 文件。然后，你需要在 `Crypto.json` 文件的 `EncryptionKey.Key` 中填写 **base64** 格式的密钥。

完成以上配置后，你需要在命令行中启用 `--encrypt` 选项：

``` Batch
.\cook-and-pack.cmd --encrypt
.\cook-and-pack.cmd --encrypt "path\to\your\own\Crypto.json"
```

就像你看到的那样，`--encrypt` 选项可以指定 `Crypto.json` 的路径，也可以不指定这个参数。在启用加密的情况下但未指定 `Crypto.json` 的路径时，会使用 `configs\Crypto.json` 文件的配置。

虚幻编辑器的加密设置不会应用于本工具。

### 保留共享着色器文件

为了缩小资产包的体积，本工具默认会删除烘焙产生的共享着色器。如有需要，你可以用 `--keep-shaders` 选项保留共享着色器文件：

``` Batch
.\cook-and-pack.cmd --keep-shaders 
```

### 自定义需要打包的资产

本工具默认只会打包 `Saved\Cooked\WindowsNoEditor\DreadHunger\Content\` 中的资产，即虚幻编辑器的文件管理器中可见的内容。有时候我们可能需要打包其他的内容，你可以编辑 `configs\PAK-filelist.txt` 文件，并启用 `--customize-packing-assets` 选项。

一个 `PAK-filelist.txt` 文件的示例如下：

```
"X:\My Workspace\DhCookPackTool\project\Saved\Cooked\WindowsNoEditor\DreadHunger\Content\*.*" "..\..\..\DreadHunger\Content\*.*" 
"X:\My Workspace\DhCookPackTool\project\Saved\Cooked\WindowsNoEditor\Engine\Content\EngineSky\VolumetricClouds\*.*" "..\..\..\Engine\Content\EngineSky\VolumetricClouds\*.*" 
```

`PAK-filelist.txt` 中，每一行有 2 个路径。其中前一个路径是需要打包的文件，后一个路径是这些文件的挂载点。在挂载点路径中，`..\..\..\` 似乎是固定的前缀（笔者也并不了解其具体细节），此目录对应的即是项目烘焙出的 `Saved\Cooked\WindowsNoEditor\` 目录。被打包的文件相对于这一目录的路径，加上 `..\..\..\` 作为前缀，即是该项的挂载点。

配置完 `PAK-filelist.txt` 文件后，你还需要在命令行中启用 `--customize-packing-assets` 选项：

``` Batch
.\cook-and-pack.cmd --customize-packing-assets
```

### 覆盖项目的 `DefaultGame.ini` 设置

`DefaultGame.ini` 文件存储了虚幻编辑器“项目设置”中的部分配置信息。工具默认会应用项目目录中 `DefaultGame.ini` 文件的配置（`<项目路径>\Config\DefaultGame.ini`）。

但如果你在烘焙打包时，需要用自定义的配置，覆盖项目的 `DefaultGame.ini` 设置，你可以在工具目录下的 `configs` 目录（即包含 `config.txt` 文件的目录）中，创建 `DefaultGame.ini` 文件。

如果 `configs\DefaultGame.ini` 文件存在，本工具会忽略项目的 `DefaultGame.ini` 文件，只应用工具目录中 `configs\DefaultGame.ini` 文件的配置。

## 已知的问题

本工具不支持增量烘焙。在每次启动时，工具会清空并重新拷贝来自虚幻编辑器的项目，并全量重新烘焙。这意味着如果需要烘焙的资产较多，本工具的运行速度可能较慢。

## 作为其他虚幻游戏模组烘焙打包的参考

本工具是为 Dread Hunger 游戏模组烘焙和打包设置的，但也可以为其他基于虚幻引擎（Unreal Engine）的游戏模组的烘焙和打包提供参考。

首先，你可能需要修改 `assets\project\DreadHunger.uproject` 文件，包括文件名。此文件是一个 JSON 文件，其中的 `"EngineAssociation": "4.26"` 指明了游戏对应的引擎版本，你需要将其修改为对应的引擎版本。

其次，你需要对 [`cook-and-pack.cmd`](./cook-and-pack.cmd) 的内容作相应的修改，尤其是其中的 `DreadHunger` 字样。文件中有较为完整的注释（以英文形式），可参照此注释进行修改。

## 开源许可和致谢

本项目采用 GNU AGPL-3.0 许可证开放源代码，详见 [LICENSE](./LICENSE) 文件。

本项目是以 Dread Hunger 模组作者 **“佬葉孒丶”** 提供的封包脚本为最初思路，逐步迭代而来的。

[`cook-and-pack.cmd`](./cook-and-pack.cmd) 脚本的 `Read command-line parameters` 部分参考了 Garret Wilson 在 Stack Overflow 上 [这个回答](https://stackoverflow.com/a/50652990) 的思路。

用于解析 JSON 文件的 [`json-extractor.cmd`](libs/json-extractor.cmd) 脚本是由 [Vasil Arnaudov](https://github.com/npocmaka) 的 [npocmaka/batch.scripts 项目的部分内容](https://github.com/npocmaka/batch.scripts/blob/master/hybrids/jscript/jsonextractor.bat) 和 [Douglas Crockford](https://www.crockford.com/) 的 [json2.js](https://github.com/douglascrockford/JSON-js/blob/master/json2.js) 融合而来的。详细信息请见 [此文件](libs/json-extractor.cmd) 的头部注释。

[OpenAI](https://openai.com/) 和 [TheB.AI](https://theb.ai/) 提供的人工智能助手为本项目的开发做出了很大的贡献。
