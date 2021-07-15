set ns [new Simulator]

set tf [open caeser.tr w]
$ns trace-all $tf

set nf [open caeser.nam w]
$ns namtrace-all $nf

proc finish {} {
	global ns tf nf
	$ns flush-trace
	close $tf
	close $nf
	exec nam file.nam &
	exit 0
}

proc encrypt {s {n 3}} {
	set r {}
	binary scan $s c* d
	foreach {c} $d {
		append r [format %c [expr {
			(($c ^ 0x40) & 0x5F) <27 ?
			(((($c ^0x40) & 0x5F) + $n - 1) % 26 +1)|($c & 0xe0)
			: $c
		}]]
	}
	return $r
}

proc decrypt {s {n 3}} {
	set n [expr {abs($n - 26)}]
	return [encrypt $s $n]
}

Agent/UDP instproc process_data {size data} {
	global ns
	$self instvar node_
	$ns trace-annotate "Packet recieved by [$node_ node-addr]: {$data}"
	set dec_msg [decrypt $data]
	$ns trace-annotate "Decoded Packet recieved by [$node_ node-addr]: {$dec_msg}" 
}

proc send_pkt {node agent msg} {
	global ns
	$ns trace-annotate "Packet sent by [$node node-addr]: {$msg}"
	set enc_msg [encrypt $msg]
	$ns trace-annotate "Encoded Packet sent by [$node node-addr]: {$enc_msg}"
	eval {$agent} send 999 {$enc_msg}
}

set nodeA [$ns node]
set nodeB [$ns node]

$nodeA color red
$nodeA label "Encrypted Node A"

$nodeB color black
$nodeB label "Encrypted Node B"

$ns duplex-link $nodeA $nodeB 0.6Mb 100ms DropTail

set enc_udpA [new Agent/UDP]
$ns attach-agent $nodeA $enc_udpA
$enc_udpA set fid_ 0

set enc_udpB [new Agent/UDP]
$ns attach-agent $nodeB $enc_udpB
$enc_udpB set fid_ 1

$ns connect $enc_udpA $enc_udpB

$ns at 0.10 "$ns trace-annotate {Encrypted Communication Started}"
$ns at 0.15 "send_pkt $nodeA $enc_udpA {Hello Cruel World}"
$ns at 0.35 "send_pkt $nodeB $enc_udpB {Bye Cruel World}"
$ns at 0.50 "$ns trace-annotate {Encrypted Communication Over}"

$ns at "finish"
$ns run
