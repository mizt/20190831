namespace OSC {
  
    #define PORT 54321
  
    #import <arpa/inet.h>
    #import "tinyosc.h"
  
    class Receiver {
      
        private:
            
            char recvbuf[0xFFFF];
            const int fd = socket(AF_INET,SOCK_DGRAM,0);
              
            virtual void onOSC(tosc_message *osc) = 0;
          
        public:
        
            Receiver(int port) {                  
                fcntl(this->fd,F_SETFL,O_NONBLOCK); // set the socket to non-blocking
                struct sockaddr_in sin;
                sin.sin_family = AF_INET;
                sin.sin_port = htons(port);
                sin.sin_addr.s_addr = INADDR_ANY;
                bind(this->fd,(struct sockaddr *)&sin,sizeof(struct sockaddr_in));
            }		
        
            void update() {
              
                fd_set readSet;
                FD_ZERO(&readSet);
                FD_SET(fd, &readSet);
                struct timeval timeout = {0,0};
                if(select(fd+1,&readSet,NULL,NULL,&timeout)>0) {
                    struct sockaddr sa; // can be safely cast to sockaddr_in
                    socklen_t sa_len = sizeof(struct sockaddr_in);
                    int len = 0;
                    while((len = (int) recvfrom(fd,recvbuf,sizeof(recvbuf),0,&sa,&sa_len))>0) {
                        if(tosc_isBundle(recvbuf)) {
                            tosc_bundle bundle;
                            tosc_parseBundle(&bundle,recvbuf,len);
                            const uint64_t timetag = tosc_getTimetag(&bundle);
                            tosc_message osc;
                            while (tosc_getNextMessage(&bundle,&osc)) {
                                this->onOSC(&osc);
                            }
                        }
                        else {
                            tosc_message osc;
                            tosc_parseMessage(&osc, recvbuf,len);
                            this->onOSC(&osc);
                        }
                    }
                }
            }
    };

    class Sender {

        private:

            struct sockaddr_in addr;
            const int udp = socket(AF_INET,SOCK_DGRAM,0);
            char buffer[0xFFFF];

        public:

            Sender(const char *ip,int port) {
                addr.sin_family = AF_INET;
                addr.sin_addr.s_addr = inet_addr(ip);
                addr.sin_port = htons(port);
            }

            ~Sender() {
                close(this->udp);
            }

            void send(const char *address, const char *format, ...) {
                if(udp) {
                    va_list ap;
                    va_start(ap,format);
                    const uint32_t len = OSC::tosc_vwrite(buffer,sizeof(buffer),address,format,ap);
                    va_end(ap);
                    sendto(udp,buffer,len,0,(struct sockaddr *)&addr,sizeof(addr));
                }
            }
        };
}
