# QUIC Load Balancer Code
This implementation contains two parts: modification on picoquic_sample of picoquic and new codes for P4 switch based on Mininet. The current LB work is stateless, based on QUIC_LB clear algorithm, and tested with simulation. Work in progress to use the obfuscated algorithm for security reasons, test with real P4 switch and implement a stateful LB.

## Prerequisites

I assume that you are using the ETH-P4 VM [link](https://github.com/nsg-ethz/p4-learning). Please refer to their tutorial to set up the environment and run the code. 

Also, picoquic needs to be installed. Please refer to [link](https://github.com/private-octopus/picoquic). Notice that prior to installing picoquic, you need to install picotls. Please refer to [link](https://github.com/h2o/picotls).

In the picoquic directory, please create two folders called `client_files` and `server_files`. Create an `index.html` in the `server_files` and write something in it.


## Network topology

Assume there is a single VIP with IP=`10.0.0.254`, a single client at `10.0.0.1` and two servers at `10.0.0.2` (`server_id = 1`) and `10.0.0.3` (`server_id = 2`), respectively. We implemented a weighted LB with 6 buckets. The first four buckets are assigned to `10.0.0.2` and the last two to `10.0.0.3`.


## Stateless QUIC_LB

This is now working with the "clear algorithm" of QUIC_LB. For testing, following the guidelines below:

Firstly, please copy the `/picoquic/sample` folder to your `picoquic` directory. Then run `make` to compile the new changes.

Then, open four terminals. One for the mininet, the other three for hosts.

On terminal 1, enter the QUIC_LB directory and run `sudo p4run`.

This will launch the Mininet enviroment.

On terminal 2, 3 and 4, enter the picoquic directory. Terminal 2 will be assigned as a client, and terminal 3 & 4 will be servers.

On the client, run `mx h1`.

On the servers, run `mx h2` and `mx h3`. Then on both servers, run `wireshark &`. This will open wireshark. Please use wireshark to monitor both the `h2-eth0` and `h3-eth0`.

Then, enable servers to be quic servers.

on h2, run `./picoquic_sample server 4443 ./certs/cert.pem ./certs/key.pem ./server_files/ 1`.

On h3, run `./picoquic_sample server 4443 ./certs/cert.pem ./certs/key.pem ./server_files/ 2`. 

The last "1" and "2" refers to server_id.

Then, enable the client to request a file from the servers.

On h1, run `./picoquic_sample client 10.0.0.254 4443 ./client_files/ index.html`. Repeat for 6 times.

Monitor on both wireshark interfaces that for the first four times, the requests would go to h2 and for the last two times, the requests would go to h3. If you see this result, the LB logic is correct.

(To be more intuitive, you can run `mx s1` to enter the switch and run `wireshark`. You can then monitor the traffic loads for `s1-eth2` and `s1-eth3` to check if the LB logic is correct

