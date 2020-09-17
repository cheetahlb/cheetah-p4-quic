# QUIC Load Balancer Code
This implementation contains two parts: modification on picoquic_sample of picoquic and new codes for P4 switch based on Mininet. The current LB work is stateless, based on QUIC_LB clear algorithm, and tested with simulation. Work in progress to use the obfuscated algorithm for security reasons, test with real P4 switch and implement a stateful LB.

This repository contains the P4 source codes. For modified picoquic, please refer to the picoquic-mod repository.

## Prerequisites

I assume that you are using the ETH-P4 VM [link](https://github.com/nsg-ethz/p4-learning). Please refer to their tutorial to set up the environment and run the code. 

## Network topology

Assume there is a single VIP with IP=`10.0.0.254`, a single client at `10.0.0.1` and two servers at `10.0.0.2` (`server_id = 1`) and `10.0.0.3` (`server_id = 2`), respectively. We implemented a weighted LB with 6 buckets. The first four buckets are assigned to `10.0.0.2` and the last two to `10.0.0.3`.


## Stateless QUIC_LB

This is now working with the "clear algorithm" of QUIC_LB. For testing, following the guidelines below:

A Makefile has been added to enable easier testing. Please make sure that you place this directory and the picoquic directory under the same directory. Only when will the Makefile work correctly

Then, please open four terminals. One for the mininet, the other three for hosts.

On terminal 1, enter the QUIC_LB directory and run sudo p4run.

This will launch the Mininet enviroment.

On terminal 2, 3 and 4, enter the picoquic directory. Terminal 2 will be assigned as a client, and terminal 3 & 4 will be servers.

On the client, run 
`mx h1`.

On the servers, run 
`mx h2` and `mx h3`
Then on both servers, run wireshark &. This will open wireshark. You can use wireshark to monitor both the h2-eth0 and h3-eth0.

Then, on h2 and h3, please run 
`make server1` and `make server2`
respectively. This will enable the hosts in the picoquic server mode.

Then, on h1, please run 
`make client`
to enable h1 in host mode. Repeat this command for 6 times.

Monitor on both wireshark interfaces that for the first four times, the requests would go to h2 and for the last two times, the requests would go to h3. If you see this result, the LB logic is correct.

(To be more intuitive, you can run `mx s1` to enter the switch and run `wireshark`. You can then monitor the traffic loads for `s1-eth2` and `s1-eth3` to check if the LB logic is correct

