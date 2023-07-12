from pprint import pprint
from lib.params import params
from lib.list_input_files import list_input_files
from lib.composite_images import composite_images
from lib.process_logfile import process_logfile


'''
    get arguments
'''

arguments = params()
boundaries = arguments["ranges"]
input_dir = arguments["dirs"]["input"]
output_dir = arguments["dirs"]["output"]
logfile_path = arguments["logs"]["log"]
alt_logfile_path = arguments["logs"]["processed"]

'''
    composite images
'''


log = open(logfile_path, "a+")


time_script_started = time.time()
def log_image_progress(item_to_log):
    log_time_difference = str(round((time.time()-time_script_started), 2))
    
    logline = log_time_difference + ":" + item_to_log + '\n'
    print(logline)
    log.write(logline)


file_list = list_input_files(input_dir)
composite_images(boundaries, file_list, output_dir, log_image_progress)
log.close()

'''
    process the logfile 
'''

log = open(logfile_path, "r")
text = log.read()
time_elapsed_log = open(alt_logfile_path, "w+")
# process_logfile(text, time_elapsed_log)
time_elapsed_log.close()
log.close()
