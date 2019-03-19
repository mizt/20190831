class Plugin {
	private:
		void *instance = nullptr;
	
	public:
		Plugin();
		~Plugin();
        virtual void exec();
};

#ifdef USE_PLUGIN
	typedef Plugin *newPlugin();
	typedef void deletePlugin(Plugin*);
#endif


