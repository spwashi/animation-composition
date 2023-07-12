#
import re
from os import listdir
from os.path import isfile, join
import time

get_file_order = lambda x: int(re.search(r'\d+',  x.split('/')[-1]).group())

def list_input_files(input_dir):
    file_list = [join(input_dir, f) for f in listdir(input_dir) if isfile(join(input_dir, f))]
    file_list.sort(key=get_file_order, reverse=True)
    print(list(map(get_file_order, file_list)))
    time.sleep(1)
    
    return file_list