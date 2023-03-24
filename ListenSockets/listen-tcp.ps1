$port = 9999
$timeout = 10
$Listener = [System.Net.Sockets.TcpListener]$port;
$Listener.Start();
sleep $timeout
#wait, try connect from another PC etc.
$Listener.Stop();
