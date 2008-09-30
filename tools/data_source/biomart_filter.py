# Greg Von Kuster
import urllib
from galaxy import eggs
from galaxy.datatypes import sniff
from galaxy import datatypes, config
import tempfile, shutil

def exec_before_job( app, inp_data, out_data, param_dict, tool=None):
    """Sets the name of the data"""
    data_name = param_dict.get( 'name', 'Biomart query' )
    data_type = param_dict.get( 'type', 'txt' )
    name, data = out_data.items()[0]
    if data_type == 'txt':
        data_type = sniff.guess_ext( data.file_name, sniff_order=app.datatypes_registry.sniff_order )
    data = app.datatypes_registry.change_datatype(data, data_type)
    data.name = data_name
    #store BIOMART parameters temporarily in output file
    out = open(data.file_name,'w')
    for key, value in param_dict.items():
        print >> out, "%s\t%s" % (key,value)
    out.close()     
    out_data[name] = data
    

def exec_after_process(app, inp_data, out_data, param_dict, tool=None, stdout=None, stderr=None):
    name, data = out_data.items()[0]
    if not isinstance(data.datatype, datatypes.interval.Bed) and isinstance(data.datatype, datatypes.interval.Interval):
        #Set meta data, format file to be valid interval type
        data.set_meta(first_line_is_header=True)
        #check for missing meta data, if all there, comment first line and process file
        if not data.missing_meta():
            line_ctr = -1
            temp = tempfile.NamedTemporaryFile('w')
            temp_filename = temp.name
            temp.close()
            temp = open(temp_filename,'w')
            chromCol = int(data.metadata.chromCol) - 1
            startCol = int(data.metadata.startCol) - 1
            strandCol = int(data.metadata.strandCol) - 1
            
            for line in open(data.file_name, 'r'):
                line_ctr += 1
                #First line is a non-commented header line, lets comment it out here
                if line_ctr == 0:
                    temp.write("#%s" % line)
                    continue
                fields = line.strip().split('\t')
                #If chrom col is an int, make it chrInt
                try:
                    int(fields[chromCol])
                    fields[chromCol] = "chr%s" % fields[chromCol]
                except:
                    try:
                        if fields[chromCol].upper()== "X" or fields[chromCol].upper()== "Y":
                            fields[chromCol] = "chr%s" % fields[chromCol].upper()
                    except:
                        pass 
                #change to BED coordinate system
                try:
                    fields[startCol] = str(int(fields[startCol]) - 1)
                except:
                    pass
                #set strand to +/-, instead of +1/-1
                try:
                    if strandCol > 0:
                        if int(fields[strandCol]) > 0:
                            fields[strandCol] = "+"
                        else:
                            fields[strandCol] = "-"
                except:
                    pass
                temp.write("%s\n" % '\t'.join(fields))
            temp.close()
            shutil.move(temp_filename,data.file_name)
        else:
            data_type = sniff.guess_ext(data.file_name)
            data = app.datatypes_registry.change_datatype(data, data_type)
            if data.missing_meta():
                data.set_meta()
    else:
        data_type = sniff.guess_ext(data.file_name)
        data = app.datatypes_registry.change_datatype(data, data_type)
        if data.missing_meta():
            data.set_meta()
    data.set_peek()
    data.set_size()
    data.flush()
