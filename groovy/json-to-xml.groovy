import groovy.json.JsonSlurper
import groovy.xml.*

def jsonFile = "HDH-HDSP-AU-20190321-090311.json"
def auths = new JsonSlurper().parse(new FileReader(jsonFile))

def renderAuth(auth){
    // println auth.getClass()
    return { 
        for (entry in auth) {
            // println "Handling ${entry}"
            switch(entry.value.getClass() ){
                case Map :
                    "${entry.key}" renderAuth( entry.value )
                    break
                case List:
                    entry.value.each { listEntry ->
                        "${entry.key}" renderAuth( listEntry )
                    }
                    break
                default :
                     //"${entry.key}"( "${entry.value}" )
                     "${entry.key}" "${entry.value}"
                break
            }
        }
    }
}


/* This works but results in one giant line */

//def writer = new StringWriter()
//def builder = new MarkupBuilder(new IndentPrinter(new PrintWriter(writer),"",false))
//builder.testing renderAuth(auths)
def fileWriter = new File("testoutput.xml").newWriter()

auths.CaseLevel.each{auth ->
    println "Converting CaseLevelReferenceNumber: ${auth.CaseLevelReferenceNumber}------"
    def writer = new StringWriter()
    def builder = new MarkupBuilder(new IndentPrinter(new PrintWriter(writer),"",false))
    builder."CaseLevel"(renderAuth(auth))

    println "Writing ${writer.toString()}"
    /*
    new File("testoutput.xml").withWriter{ 
        it << writer.toString()
    }
    */
    fileWriter.write(writer.toString() + "\n")
}
fileWriter.close()