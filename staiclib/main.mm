#import <Foundation/Foundation.h>
#import "Banana/BaseItem.h"
#import "Banana/Banana.h"

int main(int argc, char *argv[]) {
	@autoreleasepool {		
		BaseItem *item = Banana::$();
		FILE *fp = fopen("test.jpg","wb");
		if(fp!=NULL){
			fwrite(item->data,item->capter[0][1],1,fp);
			fclose(fp);
		}
		
	}
}
