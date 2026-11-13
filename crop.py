from PIL import Image
im = Image.open('logo200.png').convert('RGB')
print(im.size, im.getpixel((100,300)), im.getpixel((450,200)))
c = im.crop((190, 390, 710, 770))
c.save('flutter_app/assets/logo.png')
print(c.size)
