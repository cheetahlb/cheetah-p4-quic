/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/
const bit<16> TYPE_IPV4 = 0x0800;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<64> connID_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    dscp;
    bit<2>    ecn;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}


header udpQuic_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length;
    bit<16> checksum;
    bit<1> hdr_type;
    bit<1> fixed;
    bit<2> pkt_type;
    bit<4> version;
}


header quicLong_t{
    bit<32> version;
    bit<8> dcid_length;
    bit<8> dcid_first_byte;
    bit<16> cookie;
    bit<40> dcid_residue;
    bit<8> scid_length;
    bit<64> src_cid;
}

header quicShort_t{
    bit<8> dcid_first_byte;
    bit<16> cookie;
    bit<40> dcid_residue;
}



struct metadata {
   bit<16> bucket_id;
   bit<16> hash;
   bit<16> crc16;
   bit<16> server_id;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t ipv4;
    udpQuic_t udpQuic;
    quicShort_t quicShort;
    quicLong_t quicLong;
}
