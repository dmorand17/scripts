def commandLine(){
	scriptFile = getClass().protectionDomain.codeSource.location.path.split("//").last()
	def cli = new CliBuilder(usage: 'groovy ' + scriptFile + ' -a/-l/-r [-f] [-h] snapshot_event.log snapshot_event.log.1 ...')
	cli.h(longOpt: 'help', 'usage information', required: false )
	cli.f(longOpt: 'filter', 'Cache name filter string. Ex. "hibernate.user"', args:1, required: false)
	cli.s(longOpt: 'since', 'Analyse cache entries since specified date & time. IE. "2014/05/19 14:00"', args:1, required: false)
	cli.u(longOpt: 'until', 'Analyse cache entries until specified date & time. IE. "2014/05/20 16:00"', args:1, required: false)
	cli.l(longOpt: 'list', 'list caches name', required: false)
	cli.a(longOpt: 'averages', 'Show cache usage average', required: false)
	cli.r(longOpt: 'report', 'Show report with caches that may need tuning', required: false)

	OptionAccessor opt = cli.parse(args)
	// print usage if -h, --help, or no argument is given
	if(opt.arguments().size() == 0 || opt.h || !( opt.l || opt.a || opt.r)) {
		cli.usage()
		System.exit(0)
	}

	for ( f in opt.arguments()){
		f2 = new File(f)
		if (! f2.exists()){
			print f + " does not exist. Quitting."
			System.exit(1)
		}
	}

	return opt
}

def analyzeFiles(options){
	files = options.arguments()
	def caches = [:]

	since=null
	if (options.s) {
		try{
			since = Date.parse("yyyy/MM/dd H:m", options.s)
			}catch(Error e){
				println "Error parsing since date"
				System.exit(1)
			}
		
	}
	until=null
	if (options.b) {
		try{
			until = Date.parse("yyyy/MM/dd H:m", options.b)
			}catch(Error e){
				println "Error parsing until date"
				System.exit(1)
			}
	}

	for ( f in files){
		f2 = new File(f)
		f2.eachLine { line ->
			def cacheLineRegex = /(?<datetime>.*) \| SNAPSHOT SCALAR \'CACHE (?<name>.*) ENTRIES=(?<entries>\d+), MAX_ENTRIES=(?<maxentries>\d+), UTILIZATION=(?<utilization>\d+), HITS=(?<hits>\d+), MISSES=(?<misses>\d+), EVICTIONS=(?<evictions>\d+), GET_TIME=(?<gettime>\d+).*/
			matcher = ( line =~ cacheLineRegex )
			if( matcher.matches() ){
				datetime = Date.parse("dd MMM yyyy H:m:s,S", matcher.group('datetime'))
				name = matcher.group('name')
				entries = matcher.group('entries').toInteger()
				maxentries = matcher.group('maxentries').toInteger()
				utilization = matcher.group('utilization').toInteger()
				hits = matcher.group('hits').toInteger()
				misses = matcher.group('misses').toInteger()
				evictions = matcher.group('evictions').toInteger()
				gettime= matcher.group('gettime').toInteger()

				//Check if cache entry must be added
				if ((options.f && name.find(options.f) != null) || !options.f ){
					if ((options.s && datetime > since) || !options.s ){
						if ((options.b && datetime < until) || !options.b ){
							//Initialice cache entry if not found
							if (caches[name] == null){
								caches[name] = [ 'entries':0,'maxentries':0,'utilization':0,'hits':0,'misses':0,'evictions':0,'gettime':0,'counter':0]
								}
							//Add values to the cache entry
							caches[name]['entries'] += entries
							caches[name]['maxentries'] += maxentries
							caches[name]['utilization'] += utilization
							caches[name]['evictions'] += evictions
							caches[name]['gettime'] += gettime
							caches[name]['hits'] += hits
							caches[name]['misses'] += misses
							caches[name]['counter'] += 1
							}
						}
					}
				}
			}

		}

	//Calculating averages
	for (cache in caches){
		for (entry in caches[cache.key]){
			if (entry.key != "counter"){
				average = entry.value / caches[cache.key].counter
				//Rounding integers to two decimals
				if(entry.value instanceof Integer || entry.value instanceof java.math.BigDecimal){
					average = Math.round(average * 100) / 100
				}
				caches[cache.key][entry.key] = average
			}
		}
	}

	//Calculating misses percentage
	for (cache in caches){
		hits = caches[cache.key]['hits']
		misses = caches[cache.key]['misses']
		totalhits = hits + misses
		hitmissratio = 100
		if (totalhits!=0){
			hitmissratio = hits * 100 / totalhits
		}
		caches[cache.key]['hitmissratio'] = Math.round(hitmissratio * 100) / 100
	}

	return caches
}

def showOutput(options,caches){
	if (!options.r){
		for (cache in caches){
			if (options.l){
				println cache.key
			}else{
				println cache
			}
		}
	}else{
		
		hrhu=[]
		lrlu=[]
		lrhu=[]
		lrlue=[]
		for (cache in caches){
			//High ratio, high usage
			if (cache.value.hitmissratio > 90 && cache.value.utilization > 80){
				hrhu.add(cache)
			}
			//Low ratio, low usage
			if (cache.value.hitmissratio < 90 && cache.value.utilization < 80){
				lrlu.add(cache)
			}
			//Low ratio, high usage
			if (cache.value.hitmissratio < 90 && cache.value.utilization > 80){
				lrhu.add(cache)
			}
			//Low ratio, low usage, evections
			if (cache.value.hitmissratio < 90 && cache.value.utilization < 80 && cache.value.evictions != 0){
				lrlue.add(cache)
			}
		}
		if (hrhu.size() > 0){
			println "HIGH HITS/MISS RATIO (>90%) AND HIGH CACHE UTILIZATION AVERAGE (>80%)"
			println "Cache should be enlarged but benefits will be minimal."
			println "--------------------------------------------------------------------"
			println "Cache Key,Entries,Max Entries,Utilization,Evictions,Get Time,Hits,Misses,Hit Miss Ratio"
			for (cache in hrhu) {
		    
			    println "" + cache.key + "," +
				cache.value.entries + "," +
				cache.value.maxentries + "," +
				cache.value.utilization + "," +
				cache.value.evictions + "," +
				cache.value.gettime + "," +
				cache.value.hits + "," +
				cache.value.misses + "," +
				cache.value.hitmissratio
			}
			//println hrhu.join("\n")
			println ""
		}
		if (lrlu.size() > 0){
			println "LOW HITS/MISS RATIO (<90%) AND LOW CACHE UTILIZATION AVERAGE (<80%)"
			println "Cache candidates not being precached."
			println "-------------------------------------------------------------------"
			println "Cache Key,Entries,Max Entries,Utilization,Evictions,Get Time,Hits,Misses,Hit Miss Ratio"
			for (cache in lrlu) {
		    
			    println "" + cache.key + "," +
				cache.value.entries + "," +
				cache.value.maxentries + "," +
				cache.value.utilization + "," +
				cache.value.evictions + "," +
				cache.value.gettime + "," +
				cache.value.hits + "," +
				cache.value.misses + "," +
				cache.value.hitmissratio
			}
			// println lrlu.join("\n")
			println ""
		}
		if (lrhu.size() > 0){
			println "LOW HITS/MISS RATIO (<90%) AND HIGH CACHE UTILIZATION AVERAGE (>80%)"
			println "Cache is full and needs enlarging"
			println "----------------------------------------------------------------------"
			println "Cache Key,Entries,Max Entries,Utilization,Evictions,Get Time,Hits,Misses,Hit Miss Ratio"
			for (cache in lrhu) {
		    
			    println "" + cache.key + "," +
				cache.value.entries + "," +
				cache.value.maxentries + "," +
				cache.value.utilization + "," +
				cache.value.evictions + "," +
				cache.value.gettime + "," +
				cache.value.hits + "," +
				cache.value.misses + "," +
				cache.value.hitmissratio
			}
			// println lrhu.join("\n")
			println ""
		}
		if (lrlue.size() > 0 ){
			println "LOW HITS/MISS RATIO (<90%), LOW CACHE UTILIZATION AVERAGE (<80%) AND EVECTION AVERAGE != 0"
			println "Cache entries may be evicting too fast. Review TTI or TTL"
			println "--------------------------------------------------------------------------------------------"
			println "Cache Key,Entries,Max Entries,Utilization,Evictions,Get Time,Hits,Misses,Hit Miss Ratio"
			for (cache in lrlue) {
		    
			    println "" + cache.key + "," +
				cache.value.entries + "," +
				cache.value.maxentries + "," +
				cache.value.utilization + "," +
				cache.value.evictions + "," +
				cache.value.gettime + "," +
				cache.value.hits + "," +
				cache.value.misses + "," +
				cache.value.hitmissratio
			}
			//println lrlue.join("\n")
			println ""
		}
	}
}


options = commandLine()
caches = analyzeFiles(options)
showOutput(options,caches)