import time
import math
import os
from .open_image import get_image, image_cache
from PIL import Image

def calculate_layer_alpha(index, position):
    offset = abs(index - position)
    opacity_coefficient = .78
    opacity = round((opacity_coefficient ** offset) * 100) / 100
    return opacity

def composite_images(boundaries, image_paths, output_path, logger):
    lower_range, upper_range = boundaries

    size = None
    cache_check_counter = 0
    for index, image_path in enumerate(image_paths):
        image = get_image(index, image_path)
        
        size = size if size else image.size
        if image.size != size:
            raise ValueError('All images must have the same size')
        
        lower_index = max(index - lower_range, 0)
        upper_index = min(index + upper_range, len(image_paths))

        if cache_check_counter > lower_range + upper_range:
            delete = [key for key in image_cache if key < lower_index]
            for key in delete:
                del image_cache[key]
            cache_check_counter = 0
        cache_check_counter = cache_check_counter + 1

        relative_image_path = str(image_paths[index]).replace(os.getcwd(), '')
        logger(relative_image_path)

        layer_image = Image.new('RGBA', size)
        for idx, image_path in enumerate(image_paths[lower_index:upper_index]):
            position = lower_index + idx
            opacity = calculate_layer_alpha(index, position)
            image = get_image(position, image_path)
            copied = image.copy()
            alpha_channel = Image.new('L', size, int(255 * opacity))
            copied.putalpha(alpha_channel)

            layer_image = Image.alpha_composite(layer_image, copied)
        
        layer_image.save(output_path + '/' + str(index) + '.webp')

