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

    function trimValue(&$value,$key) {
        $value=trim($value);
        $valueArray
    }
    array_walk($values, "trimValue");

    foreach ($values as $value) {
        $kv = explode(":", $value);
        $kv[0] = trim($kv[0]);
        $kv[1] = trim($kv[1]);

        if ()
        $valueArray[trim($kv[0])] = trim($kv[1]);
    }

    foreach ($keys as $key) {
        $tempKey = trim($key)
        if ($curResult[$tempKey]) {
            $curResult[$tempKey] = array();
        }

        if ($values[""]

        $curResult[$tempKey][]
    }

    // echo "posL:$posL, posR:$posR";
    echo "\nstr1:$str1\nstr2:$str2\n";
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
        $result[$line] = $curResult;
    }

    if (!$isInMedia)
    {
        continue;
    }

    // echo $line;

    parserLine($line);

    checkMediaEnd($line);
}

fclose($file);
