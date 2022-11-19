<!DOCTYPE html>
<html>
<head>
    <title>DL7ATA/ELENATA Simple State</title>
    <meta http-equiv="refresh" content="20"/>
<head>

<style>
body {
    font-family: arial,verdana, sans-serif;
        font-size: 13px;
        color: white;
        background: #08a0ff;
        }
table, th, td {
    border: 0px solid black;
    border-collapse: collapse;
}
</style>
<body style>
<left><a href="pv.php"><img src="elenata.jpg" width="48%" border="0"></a></center><pre>
<?php
# ACHTUNG svxlink.log Pfadangaben anpassen !!!
$externip=shell_exec('curl v4.ident.me');
$callsign=shell_exec('grep CALLSIGN=EL /etc/svxlink/svxlink.conf | cut -d"=" -f2');
$svxlinkversion = shell_exec('cat /tmp/svx_version');
$letzteEcholink = shell_exec('tail -15 /var/www/html/elconnects.txt');
$letztesvxlog = shell_exec('tail -15 /var/log/svxlink | cut -c 1-78');
$letzterNetlink = shell_exec('cat /var/log/svxlink | grep " Node " | tail');
$gpiostatus = shell_exec('/usr/local/bin/gpio readall | egrep "GPIO 0|CE0|CE1|GPIO 5|GPIO 6" | cut -d "|" -f3,6,7 | sed -e "s/17/LÜFTER/" -e "s/24/ TRX_2/" -e "s/25/ TRX_1/" -e "s/8/SQL_2/" -e "s/7/SQL_1/"');
$callback = shell_exec('tac /var/www/html/callback.txt | head -n 5');
$cputemp = shell_exec("cat /tmp/svx_cpu_temp | sed -n '/set Temperatur_soc/p' | sed -e 's/set Temperatur_soc //'");
$pmutemp = shell_exec("cat /tmp/svx_cpu_temp | sed -n '/set Temperatur_pmu/p' | sed -e 's/set Temperatur_pmu //'");
$chathist = shell_exec('tail -n 8 /var/www/html/chat.hist');
$svxinfo = shell_exec('df -h /;svx_pid=$(pidof svxlink);if [ $? -ne 0 ]; then echo "<H1><font color=red>Oopss....BITTE SVXLINK NEUSTARTEN</font></H1>";exit 0;else top -b -p $svx_pid -o %CPU -o TIME+ -n 1; fi');

echo "{$svxinfo}";
echo "<hr><table><tr><th>Node:{$callsign}<th> ExIP:{$externip}<th> CPU Temp:{$cputemp}<th> PMU Temp:{$pmutemp}<th> {$svxlinkversion}<th></tr></table>";

echo "<hr><table style=\"width:100%\"><tr><th>EchoLink</th><th>SvxLog</th></tr><br>";
echo "<tr><td>{$letzteEcholink}</td><td>{$letztesvxlog}</td>";
echo "</tr></table>";

echo "<hr><table style=\"width:100%\"><tr><th>GPIO</th><th>Chat und APRS-Msg</th></tr>";
echo "<tr><td>{$gpiostatus}Linkstatus RemoteLogic  {$linkstatus1}Linkstatus Netlogic2    {$linkstatus2}PV-Strom                 {$PV_Strom}PV-Spannung             {$PV_Spannung}Temperatur              {$akt_temp}<br>Sonnenauf-/unterg. {$sunset}</td>";
echo "<td>{$chathist}</td></tr></table>";

echo "<hr><table style=\"width:100%\"><tr><th>Letzte 10 Netlink An- bzw. Abmeldungen</th><th>Rückrufe</th></tr>";
echo "<tr><td>{$letzterNetlink}</td><td>{$callback}</td></tr></table>";

echo "<hr><table style=\"width:100%\"><tr><th></th></tr>";

$timestamp = time();
$datum = date("d.m.Y - H:i", $timestamp);
echo "Seite abgerufen:  $datum";
?>

</table>

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons Lizenzvertrag" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/80x15.png" /></a><font size="1"> v25.01.2016 do7en/modified by DL7ATA</font>
</body>
</html>

