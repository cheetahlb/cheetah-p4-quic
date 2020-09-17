/*************************************************************************
*********************** P A R S E R  *******************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
    	transition select(hdr.ipv4.protocol){
    		17: parse_udpQuic;
    		default: accept;
        }
    }

    state parse_udpQuic {
        packet.extract(hdr.udpQuic);
    	transition select(hdr.udpQuic.hdr_type){
    		0: parse_quicShort;
            1: parse_quicLong;
    		default: accept;
        }
    }

    state parse_quicShort {
        packet.extract(hdr.quicShort);
        transition accept;
    }

    state parse_quicLong {
        packet.extract(hdr.quicLong);
        transition accept;
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        //parsed headers have to be added again into the packet.
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udpQuic);
        packet.emit(hdr.quicShort);
        packet.emit(hdr.quicLong);
    }
}