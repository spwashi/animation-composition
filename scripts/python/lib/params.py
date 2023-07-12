from os.path import join, abspath
from os import environ
import json
from pprint import pprint
import time

cwd = abspath(".")


psd_input_dirname = environ.get("SPWASHI_PSD_LAYER_DIRNAME")
output_dirname = environ.get("SPWASHI_OUTPUT_DIRNAME")
depth = int(environ.get("SPWASHI_COMPOSITE_DEPTH") or 13)
psd_input_filename = environ.get("SPWASHI_INPUT_PSD_NAME")                                 
def params():
    print('params')
    in_dir = join(cwd, "in", psd_input_dirname)
    input_psd = join(cwd, "in", psd_input_filename)
    input_psd_layers_dir = join(cwd, "in", psd_input_dirname)
    out_dir = join(cwd, "out", output_dirname, "frames")
    log_filepath = join(cwd, "out", output_dirname, "logs/log.txt")
    report_filepath = join(cwd, "out", output_dirname, "logs/log.processed.txt")
    
    ret = {
        "ranges": (depth, depth),
        "logs": {"log": log_filepath, "processed": report_filepath},
        "input-psd": input_psd,
        "psd-png-path": input_psd_layers_dir,
        "composite-path": join(cwd, "out", output_dirname, "still.flattened.png"),
        "dirs": {"input": in_dir, "output": out_dir},
    }
    print(json.dumps(ret, indent=4))
    time.sleep(1)

    return ret
