<?php

function help()
{
    echo <<<EOT

Trans css image to plist format

Usage:
    css2plist css_filename

Example:
    -- create files MyClasses_luabinding.cpp, MyClasses_luabinding.h
    css2plist main.css


EOT;

    exit(1);
}

function checkMediaEnd($str)
{
    global $isInMedia;
    global $braceCount;
    $count = 0;
    $count += substr_count($str, "{");
    $count -= substr_count($str, "}");
    $braceCount += $count;
    
    if ($braceCount < 1)
    {
        $isInMedia = false;
    }
    else
    {
        $isInMedia = true;
    }

    // echo "braceCount: $braceCount, isMedia:$isInMedia, str:$str, count:$count\n";
}

function trimValue(&$value, &$key) {
    $value = trim($value);
    $key = trim($key);
}

function parserLine($str)
{
    global $curResult;
    $posL = strpos($str, "{");
    $posR = strpos($str, "}");
    if (!$posL or !$posR) {
        return;
    }

    $str1 = substr($str, 0, $posL);
    $str2 = substr($str, $posL + 1, $posR - $posL - 1);

    $keys = str_word_count($str1, 1);
    $keys = array_unique($keys);
    $keys = array_values($keys);
    $values = explode(";", $str2);
    $valueArray = array();

    array_walk($values, "trimValue");

    foreach ($values as $value) {
        $kv = explode(":", $value);
        if (count($kv) < 2) {
            continue;
        }
        $kv[0] = trim($kv[0]);
        $kv[1] = trim($kv[1]);

        // echo "KV:\n";
        // print_r($kv);

        if (0 == substr_compare("background", $kv[0], 0) || 0 == substr_compare("background-image", $kv[0], 0)) {
            $temp = explode(" ", $kv[1]);
        //     echo "temp:\n";
        // print_r($temp);
            $pos = strpos($temp[0], "url('");
            if ($pos !== false) {
                $posR = strpos($temp[0], "')", $pos);
                $valueArray["background"] = substr($temp[0], $pos + 5, $posR - $pos - 5);

                $isXset = false;
                foreach ($temp as $px) {
                    if (false !== strpos($px, "px")) {
                        if (!$isXset) {
                            $valueArray["x"] = -intval($px);
                            $isXset = true;
                        } else {
                            $valueArray["y"] = -intval($px);
                        }
                    }
                }
            }
        } elseif (0 == substr_compare("background-position", $kv[0], 0)) {
            $temp = explode(" ", $kv[1]);
            $valueArray["x"] = -intval($temp[0]);
            $valueArray["y"] = -intval($temp[1]);
        } elseif (0 == substr_compare("width", $kv[0], 0)) {
            $valueArray["width"] = intval($kv[1]);
        } elseif (0 == substr_compare("height", $kv[0], 0)) {
            $valueArray["height"] = intval($kv[1]);
        }

// echo "valueArray:\n";
//         print_r($valueArray);
    }

    foreach ($keys as $key) {
        $tempKey = trim($key);
        if (!isset($curResult[$tempKey])) {
            $curResult[$tempKey] = array();
        }

        $curResult[$tempKey] = array_merge($curResult[$tempKey], $valueArray);
    }

    // echo "curResult:\n";
    //     print_r($curResult);

    // echo "posL:$posL, posR:$posR";
    // echo "\nstr1:$str1\nstr2:$str2\n";
}


if (!isset($argv))
{
    echo "\nERR: PHP \$argv not declared.\n";
    help();
}

if (count($argv) > 2)
{
    help();
}

// check command line parameters
$parameters = array();
array_shift($argv);

while (!empty($argv))
{
    $arg = array_shift($argv);
    $parameters['css_filename'] = $arg;
}

$input_path = realpath($parameters['css_filename']);
if (!file_exists($parameters['css_filename']))
{
    printf("\nERR: file \"%s\" not found.\n", $parameters['css_filename']);
    help();
}
$parameters['input_path'] = $input_path;

// read file
$file = fopen($parameters['css_filename'],"r");

$isInMedia = false;
$braceCount = 0;
$result = array();
$curResult;

while(!feof($file))
{
    $line = fgets($file);
    $pos = strpos($line, "@media");
    if ($pos !== false)
    {
        $isInMedia = true;
        $braceCount = 0;

        $curResult = array();
        $result[trim($line)] = &$curResult;
    }

    if (!$isInMedia)
    {
        continue;
    }

    // echo $line;

    parserLine($line);

    checkMediaEnd($line);

    // echo "result:\n";
    // print_r($result);
}

fclose($file);

// echo "RESULT:\n";
// print_r($result);

// format array
$background = array();
foreach ($result as $media) {
    foreach ($media as $name => $block) {
        // echo "name: $name\n";
        if (isset($block["background"])) {
            $bgName = pathinfo($block["background"])["filename"] . ".plist";
            // echo "bgName: $bgName\n";
            if (!isset($background[$bgName])) {
                $background[$bgName] = array();
            }
            if (!isset($background[$bgName][$name])) {
                $background[$bgName][$name] = $block;
            }
        }
    }
}

// echo "RESULT:\n";
// print_r($background);


// output file
$plistFirst = <<<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>frames</key>
        <dict>
EOT;

$plistEnd = <<<EOT

        </dict>
        <key>metadata</key>
        <dict>
            <key>format</key>
            <integer>2</integer>
            <key>realTextureFileName</key>
            <string>spritesheet.png</string>
            <key>size</key>
            <string>{422,777}</string>
            <key>smartupdate</key>
            <string>$TexturePacker:SmartUpdate:0c7d891dccd5629d6b2d8328e601f7d0:98ec969c68102aaee5057a91e4d43fb1:1de88c2a7237d4cdf78de8d8ad4f4c7e$</string>
            <key>textureFileName</key>
            <string>spritesheet.png</string>
        </dict>
    </dict>
</plist>

EOT;

foreach ($background as $fileName => $values) {
    $file = fopen("$fileName", "w");
    fwrite($file, $plistFirst);

    foreach ($values as $frameName => $frameVal) {
        $strFrame = sprintf("
            <key>%s.png</key>
            <dict>
                <key>frame</key>
                <string>{{%d,%d},{%d,%d}}</string>
                <key>offset</key>
                <string>{0,0}</string>
                <key>rotated</key>
                <false/>
                <key>sourceColorRect</key>
                <string>{{0,0},{%d,%d}}</string>
                <key>sourceSize</key>
                <string>{%d,%d}</string>
            </dict>",
            $frameName,
            $frameVal["x"], $frameVal["y"], $frameVal["width"], $frameVal["height"],
            $frameVal["width"], $frameVal["height"],
            $frameVal["width"], $frameVal["height"]);
        fwrite($file, $strFrame);
    }

    fwrite($file, $plistEnd);
    fclose($file);
}


// echo "RESULT:\n";
// print_r($result);
