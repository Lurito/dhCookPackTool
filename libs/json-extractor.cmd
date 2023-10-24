@if (@CodeSection == @Batch) @then

:: This script is based on npocmaka/batch.scripts on Github,
:: which is licensed under the MIT License.
:: Copyright (c) 2014 Vasil Arnaudov (source script)
:: Source: https://github.com/npocmaka/batch.scripts/blob/master/hybrids/jscript/jsonextractor.bat
:: Source license: The MIT License (https://github.com/npocmaka/batch.scripts/blob/master/LICENSE)
::
:: The JSON object in this script is based on douglascrockford/JSON-js on Github.
:: The author Douglas Crockford has declared this content to be in the public domain.
:: Source: https://github.com/douglascrockford/JSON-js/blob/master/json2.js
::
:: This modified version includes additional optimizations and enhancements implemented by Ayrzo.
:: License: The GNU Affero General Public License (GNU AGPL-3.0, see ../LICENSE)
::
:: Usage in batch: for /f "tokens=* delims=" %%a in ('json-extractor.cmd json-file.json myVariable') do set "myVariable=%%~a"
:: Note: The output of this script is formatted as JSON, some characters (such as backslashes) will be escaped

@echo off & setlocal

cscript /nologo /e:JScript "%~f0" %*
goto :EOF

@end // end batch / begin JScript hybrid chimera

var JSON = {};

(function () {
    "use strict";

    var rx_one = /^[\],:{}\s]*$/;
    var rx_two = /\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g;
    var rx_three = /"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g;
    var rx_four = /(?:^|:|,)(?:\s*\[)+/g;
    var rx_escapable = /[\\"\u0000-\u001f\u007f-\u009f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;
    var rx_dangerous = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;

    function f(n) {
        return (n < 10)
            ? "0" + n
            : n;
    }

    function this_value() {
        return this.valueOf();
    }

    if (typeof Date.prototype.toJSON !== "function") {
        Date.prototype.toJSON = function () {
            return isFinite(this.valueOf())
                ? (
                    this.getUTCFullYear()
                    + "-"
                    + f(this.getUTCMonth() + 1)
                    + "-"
                    + f(this.getUTCDate())
                    + "T"
                    + f(this.getUTCHours())
                    + ":"
                    + f(this.getUTCMinutes())
                    + ":"
                    + f(this.getUTCSeconds())
                    + "Z"
                )
                : null;
        };

        Boolean.prototype.toJSON = this_value;
        Number.prototype.toJSON = this_value;
        String.prototype.toJSON = this_value;
    }

    var gap;
    var indent;
    var meta;
    var rep;

    function quote(string) {
        rx_escapable.lastIndex = 0;
        return rx_escapable.test(string)
            ? "\"" + string.replace(rx_escapable, function (a) {
                var c = meta[a];
                return typeof c === "string"
                    ? c
                    : "\\u" + ("0000" + a.charCodeAt(0).toString(16)).slice(-4);
            }) + "\""
            : "\"" + string + "\"";
    }

    function str(key, holder) {
        var i;          
        var k;          
        var v;          
        var length;
        var mind = gap;
        var partial;
        var value = holder[key];

        if (
            value
            && typeof value === "object"
            && typeof value.toJSON === "function"
        ) {
            value = value.toJSON(key);
        }

        if (typeof rep === "function") {
            value = rep.call(holder, key, value);
        }

        switch (typeof value) {
        case "string":
            return quote(value);
        case "number":
            return (isFinite(value))
                ? String(value)
                : "null";
        case "boolean":
        case "null":
            return String(value);
        case "object":
            if (!value) {
                return "null";
            }

            gap += indent;
            partial = [];

            if (Object.prototype.toString.apply(value) === "[object Array]") {
                length = value.length;
                for (i = 0; i < length; i += 1) {
                    partial[i] = str(i, value) || "null";
                }
                v = partial.length === 0
                    ? "[]"
                    : gap
                        ? (
                            "[\n"
                            + gap
                            + partial.join(",\n" + gap)
                            + "\n"
                            + mind
                            + "]"
                        )
                        : "[" + partial.join(",") + "]";
                gap = mind;
                return v;
            }

            if (rep && typeof rep === "object") {
                length = rep.length;
                for (i = 0; i < length; i += 1) {
                    if (typeof rep[i] === "string") {
                        k = rep[i];
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (
                                (gap)
                                    ? ": "
                                    : ":"
                            ) + v);
                        }
                    }
                }
            } else {
                for (k in value) {
                    if (Object.prototype.hasOwnProperty.call(value, k)) {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (
                                (gap)
                                    ? ": "
                                    : ":"
                            ) + v);
                        }
                    }
                }
            }

            v = partial.length === 0
                ? "{}"
                : gap
                    ? "{\n" + gap + partial.join(",\n" + gap) + "\n" + mind + "}"
                    : "{" + partial.join(",") + "}";
            gap = mind;
            return v;
        }
    }

    meta = {
        "\b": "\\b",
        "\t": "\\t",
        "\n": "\\n",
        "\f": "\\f",
        "\r": "\\r",
        "\"": "\\\"",
        "\\": "\\\\"
    };
    JSON.stringify = function (value, replacer, space) {
        var i;
        gap = "";
        indent = "";

        if (typeof space === "number") {
            for (i = 0; i < space; i += 1) {
                indent += " ";
            }

        } else if (typeof space === "string") {
            indent = space;
        }

        rep = replacer;
        if (replacer && typeof replacer !== "function" && (
            typeof replacer !== "object"
            || typeof replacer.length !== "number"
        )) {
            throw new Error("JSON.stringify");
        }

        return str("", {"": value});
    };
    JSON.parse = function (text, reviver) {
        var j;
        function walk(holder, key) {

            var k;
            var v;
            var value = holder[key];
            if (value && typeof value === "object") {
                for (k in value) {
                    if (Object.prototype.hasOwnProperty.call(value, k)) {
                        v = walk(value, k);
                        if (v !== undefined) {
                            value[k] = v;
                        } else {
                            delete value[k];
                        }
                    }
                }
            }
            return reviver.call(holder, key, value);
        }

        text = String(text);
        rx_dangerous.lastIndex = 0;
        if (rx_dangerous.test(text)) {
            text = text.replace(rx_dangerous, function (a) {
                return (
                    "\\u"
                    + ("0000" + a.charCodeAt(0).toString(16)).slice(-4)
                );
            });
        }

        if (
            rx_one.test(
                text
                    .replace(rx_two, "@")
                    .replace(rx_three, "]")
                    .replace(rx_four, "")
            )
        ) {

            j = eval("(" + text + ")");

            return (typeof reviver === "function")
                ? walk({"": j}, "")
                : j;
        }

        throw new SyntaxError("JSON.parse");
    };
}());

var jsloc=WScript.Arguments.Item(0);
var jsonPath=WScript.Arguments.Item(1);

var FSOObj = new ActiveXObject("Scripting.FileSystemObject");
var jsonFile = FSOObj.OpenTextFile(jsloc,1);
var json = jsonFile.ReadAll();

try {
    var jParsed=JSON.parse(json);
} catch (err) {
    WScript.Echo("Failed to parse the json content");
    jsonFile.close();
    WScript.Exit(1);
    //WScript.Echo(err.message);
}

WScript.Echo(eval("JSON.stringify(jParsed."+jsonPath+")"));

jsonFile.close();
