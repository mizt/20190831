### Finder Sync Extension

<ol>
	<li>Open XCode project.</li>
	<li>Pick File → New → Target…</li>
	<li>Choose "Finder Sync Extension". </li>
</ol>

	-(instancetype)init {
   		self = [super init];
   		self.myFolderURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/Users/%@",NSUserName()]];
    [FIFinderSyncController defaultController].directoryURLs = [NSSet setWithObject:self.myFolderURL];
   		return self;
	}
