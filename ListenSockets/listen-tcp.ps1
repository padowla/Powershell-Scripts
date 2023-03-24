$port = 9999
$timeout = 10
$Listener = [System.Net.Sockets.TcpListener]$port;
$Listener.Start();
sleep $timeout
$Listener.Stop();
echo "Done!"
