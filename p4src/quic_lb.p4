/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/
#include "include/headers.p4"
#define BUCKET_SIZE 6
#define COUNTER_WIDTH 16

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/
#include "include/parsers.p4"



/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    
    bit<32> virtual_ip = 0x0a0000fe;
    bit<48> client_mac = 0x00000a000001;
   
    //Counter for the WRR
    register<bit<COUNTER_WIDTH>>(1) bucket_counter;

    //A register for debugging, internal use only
    register<bit<16>>(1) debug_hash;

    action crc_hash(bit<16> port, bit<32> addr){
        hash(meta.crc16, HashAlgorithm.crc16, (bit<16>)0, {port, addr}, (bit<16>)65535);
    }

    action fwd_to_server(bit<9> egress_port, bit<32> dip, bit<48> dmac) {
        hdr.ipv4.dstAddr = dip;
        hdr.ethernet.dstAddr = dmac;
        standard_metadata.egress_spec = egress_port;
    }

/*
    action fwd_to_client(bit<9> egress_port, bit<32> sip, bit<48> smac) {
        hdr.ipv4.srcAddr = virtual_ip;
        hdr.ethernet.dstAddr = client_mac;
        standard_metadata.egress_spec = egress_port;
    }
*/

    table get_server_from_bucket {
        key = {
            meta.bucket_id: exact;
        }
        actions = {
            fwd_to_server;
        }
        size = 1024;
   }

   table get_server_from_id_long_header {
        key = {
            meta.server_id: exact;
        }
        actions = {
            fwd_to_server;
        }
        size = 1024;
   }

   table get_server_from_id_short_header {
        key = {
            meta.server_id: exact;
        }
        actions = {
            fwd_to_server;
        }
        size = 1024;
   }
/*
   table get_client {
        key = {
            hdr.quicLong.server_id: exact;
        }
        actions = {
            fwd_to_client;
        }
        size = 1024;
   }
*/


        // Incremental checksum fix adapted from the pseudocode at https://p4.org/p4-spec/docs/PSA-v1.1.0.html#appendix-internetchecksum-implementation
    action ones_complement_sum(in bit<16> x, in bit<16> y, out bit<16> sum) {
        bit<17> ret = (bit<17>) x + (bit<17>) y;
        if (ret[16:16] == 1) {
            ret = ret + 1;
        }
        sum = ret[15:0];
    }

    // Restriction: data is a multiple of 16 bits long
    action subtract(inout bit<16> sum, bit<16> d) {
            ones_complement_sum(sum, ~d, sum);
    }

    action subtract32(inout bit<16> sum, bit<32> d) {
            ones_complement_sum(sum, ~(bit<16>)d[15:0], sum);
            ones_complement_sum(sum, ~(bit<16>)d[31:16], sum);
    }

    action add(inout bit<16> sum, bit<16> d) {
            ones_complement_sum(sum, d, sum);
    }

    action add32(inout bit<16> sum, bit<32> d) {
            ones_complement_sum(sum, (bit<16>)(d[15:0]), sum);
            ones_complement_sum(sum, (bit<16>)(d[31:16]), sum);
    }


    apply {
        bit <16> sum = 0;
        subtract(sum, hdr.udpQuic.checksum);
        subtract32(sum, hdr.ipv4.dstAddr);
        subtract32(sum, hdr.ipv4.srcAddr);
        subtract(sum, hdr.udpQuic.length);
        
        if(hdr.udpQuic.isValid()){                  //Only process Quic packets
            if(hdr.ipv4.dstAddr == virtual_ip) {    //packet from client
                if((hdr.udpQuic.hdr_type == 1) && (hdr.udpQuic.pkt_type == (bit<2>)0)){      //Initial, must be long header
                    bucket_counter.read(meta.bucket_id, 0);
                    
                    // we use the bucket index to find the server
                    get_server_from_bucket.apply();
                    
                    
                    // new connection, update counter
                    meta.bucket_id = meta.bucket_id + 1;

                    //Do the wrapping
                    if (meta.bucket_id == BUCKET_SIZE) {
                        meta.bucket_id = 0;
                    }
                    bucket_counter.write(0, meta.bucket_id);
                }
                else {                               //non-Initial, the dcid must have a server_id.
                    if (hdr.udpQuic.hdr_type == 1){
                        crc_hash(hdr.udpQuic.srcPort, hdr.ipv4.srcAddr);
                        debug_hash.write(0, meta.crc16);
                        meta.server_id = meta.crc16 ^ hdr.quicLong.cookie;
                        get_server_from_id_long_header.apply();
                    }
                    else{
                        crc_hash(hdr.udpQuic.srcPort, hdr.ipv4.srcAddr);
                        meta.server_id = meta.crc16 ^ hdr.quicShort.cookie;
                        get_server_from_id_short_header.apply();
                    }
                }
            }

            else {                                   //packet from servers. Just forward to the client.
                hdr.ipv4.srcAddr = virtual_ip;
                hdr.ethernet.dstAddr = client_mac;
                standard_metadata.egress_spec = (bit<9>)1;
            }
        }


        add(sum, hdr.udpQuic.length);
        add32(sum, hdr.ipv4.srcAddr);
        add32(sum, hdr.ipv4.dstAddr);
        
        hdr.udpQuic.checksum = ~sum;

    }

}


/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {


    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
   // bit<8> eight_zeroes = (bit<8>)0; 
    apply {
        update_checksum(
            hdr.ipv4.isValid(),
                {
                    hdr.ipv4.version,
                    hdr.ipv4.ihl,
                    hdr.ipv4.dscp,
                    hdr.ipv4.ecn,
                    hdr.ipv4.totalLen,
                    hdr.ipv4.identification,
                    hdr.ipv4.flags,
                    hdr.ipv4.fragOffset,
                    hdr.ipv4.ttl,
                    hdr.ipv4.protocol,
                    hdr.ipv4.srcAddr,
                    hdr.ipv4.dstAddr 
                },
                hdr.ipv4.hdrChecksum,
                HashAlgorithm.csum16
        );   
    }
}


/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;