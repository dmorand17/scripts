import org.apache.commons.cli.Option

/*
*   input file should be a separated file in the following format:
*   "subset-id":438000010135,"next-item":value
*/

/*
 static void exitWithMessage(String message) {
    System.err.println(message)
    cli.usage()
    System.exit(1)
  }
*/

def displaySection(section){
    println "\n=================================================="
    // make sure it displays in the middle 
    println "${section.center(50,'-')}"
    println "=================================================="
}

def getEngine(engine){
    // ["xml","simple"].contains(opt.e) || exitWithMessage('Unknown engine ' + opt.e)
    def engineObj = null
    switch(engine){
        case "xml":
            engineObj = new groovy.text.XmlTemplateEngine()
            break
        case "simple":
            engineObj = new groovy.text.SimpleTemplateEngine()
        default:
            // invalid engine sent
			println "Invalid engine sent ${engine}"
            System.exit(1)
    }
	println "Engine selected: ${engine}"
    return engineObj
}

final def EOL_UNIX = "\n"
final def EOL_WINDOWS = "\r\n"

//  START processing Arguments
def cli = new CliBuilder(usage: 'TemplateBuilder.groovy [-h] -t <template-file> [-o output-file] [-e engine]')
// Create the list of options.
cli.with {
    h longOpt: 'help', 'Show usage information', required: false
    t longOpt: 'template-file','Template file to be used for building output file', args: 1, required: true
    b longOpt: 'bindingArgs','bindingArgs to be used for mapping input-file into template-file', args: Option.UNLIMITED_VALUES, valueSeparator: ';', required: true
    i longOpt: 'input-file','Input file to be used for sourcing the template', args: 1, required: true
    o longOpt: 'output-file','Optional: Output file containing results.  Defaults to output.txt', args: 1, required: false
    e longOpt: 'engine','Optional: Template engine to be used ("xml","simple").  Defaults to SimpleTemplateEngine', args: 1, required: false
}
    
def opt = cli.parse(args)

if (!opt) return // No options, return
if (opt.h) cli.usage() // Show usage text when -h or --help option is used.

def templateFile = opt.'template-file'
def inputFile = opt.'input-file'
def bindingArgs = opt.bs
def outputFilename = opt.o ? opt.o : "output.txt"
def engine = opt.e ? getEngine(opt.'engine') : new groovy.text.SimpleTemplateEngine();

displaySection "ARGUMENTS"
println "Template: ${templateFile}\nInputFile: ${inputFile}\noutputFile: ${outputFilename}\nengine: ${engine}\nbinding: ${bindingArgs}\n"
//  FINISH processing Arguments

//  START processing Input
displaySection "PROCESSING INPUT"
// Iterate over the csv 
def binding = null
def templateEles = []
new File(inputFile).splitEachLine(";"){ fields ->
    // ensure that the length of fields matches the number of bindingArgs
    
    if (fields.size() != bindingArgs.size()){
        println "Incorrect number of fields, expected:${bindingArgs.size()}: ${fields}"
        return
    }

    //new Expando()
    // Creating binding per row
    binding = [:]
    bindingArgs.eachWithIndex{bindingArg,idx ->
        //print "${bindingArg}:${fields[idx]}"
        //binding << [:fields[idx]]
        binding."$bindingArg" = fields[idx]
        //binding.bindingArg = fields[idx]
    }
    // println ""
    println "Processing entry ${binding}"
    templateEles << engine.createTemplate(new File(templateFile).text).make(binding).toString() // Returns string representation of the XML
}

displaySection "RESULTS"
templateEles.each{ println "${it}"}
//  FINISH processing Input

//  START processing output file
displaySection "BUILDING OUTPUT FILE"
// Creating the Output File
outputFile = new File(outputFilename)
// Re-create file
if(outputFile.exists()){
	println "Deleting ${outputFile.path} (${outputFile.absolutePath})..."
	outputFile.delete()
} 
// Write the results to output file
outputFile.withWriter {writer -> 
    templateEles.each{writer.writeLine it}
}
//outputFile << templateEles.each{println ${it}}
println "${templateEles.size()} records written"
//  FINISH processing output file