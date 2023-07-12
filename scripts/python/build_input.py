from os import makedirs
from os.path import abspath, join
from psd_tools import PSDImage
from lib.params import params



arguments = params()
psd_path = arguments["input-psd"]
file_dir = arguments["psd-png-path"]
composite_path = arguments["composite-path"]

try:
    makedirs(file_dir, exist_ok=True)
except FileExistsError:
    pass


psd = PSDImage.open(psd_path)
psd.composite().save(composite_path)

def generate_png_files(psd_png_path, psd):
    i = 0
    for layer in psd:
        print(layer)
        layer_image = layer.composite()
        file_name = str(i) + ' -- ' + layer.name
        layer_image.save(join(psd_png_path, '%s.png') % file_name)
        i = i + 1

generate_png_files(file_dir, psd)
