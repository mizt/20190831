#import "sys/sysctl.h"

int isRunningApp(NSString *AppName) {
    
    // https://developer.apple.com/documentation/kernel/task_snapshot/1551747-p_comm
    NSString *uid = ([AppName length]>16)?[AppName substringWithRange:NSMakeRange(0,16)]:AppName;
            
    int mibname[4] = {CTL_KERN,KERN_PROC,KERN_PROC_ALL,0};
    size_t size = 0;
    
    if(sysctl(mibname,4,NULL,&size,NULL,0)<0) return -1;
    
    struct kinfo_proc *process = (struct kinfo_proc *)malloc(size);
    if(sysctl(mibname,4,process,&size,NULL,0)<0) {
        free(process);
        return -1;
    }

    unsigned long count = size/sizeof(struct kinfo_proc);
    for(int i=0; i<count; i++) {
        
        pid_t pid = process[i].kp_proc.p_pid;
        char *name = process[i].kp_proc.p_comm;
        
        NSString *processName = [[NSString alloc] initWithData:[NSData dataWithBytes:name length:strlen(name)] encoding:NSUTF8StringEncoding];
            
        if([processName compare:uid]==NSOrderedSame) {
            free(process);            
            return pid;
        }
    }
    free(process);
    return -1;
}