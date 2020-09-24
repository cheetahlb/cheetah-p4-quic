server1:
	cd picoquic && ./picoquic_sample server 4443 ./certs/cert.pem ./certs/key.pem ./server_files 1

server2:
	cd picoquic && ./picoquic_sample server 4443 ./certs/cert.pem ./certs/key.pem ./server_files 2

client:
	arp -s 10.0.0.254 a1:23:e3:8d:4b:01 && cd ../picoquic && ./picoquic_sample client 10.0.0.254 4443 ./client_files index.html
