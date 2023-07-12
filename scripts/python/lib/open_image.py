from PIL import Image

def process_image(image):
    return image

    # left here for performance comparison
    arr = np.asarray(image)
    arr[(arr > 250).all()] = [255,255,255,0]
    return Image.fromarray(arr)

image_cache = {}
def get_image(index, image_path):
    try:
        image_cache[index]
        image = image_cache[index]
    except KeyError:
        image = Image.open(image_path).convert('RGBA')
        image = process_image(image)
        image_cache[index] = image
    return image