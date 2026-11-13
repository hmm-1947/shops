from PIL import Image
def p(f, pts):
    im = Image.open(f).convert('RGB')
    for n,(x,y) in pts.items():
        r,g,b = im.getpixel((x,y))
        print(f, n, '#%02X%02X%02X'%(r,g,b))
p('ottp2.png', {'btn':(230,987),'otpbox_bg':(194,897),'otpbox_border':(176,897),'bg':(300,1200),'screenbg2':(260,1150)})
p('home_full.png', {'bg':(200,640),'prodcard':(205,760),'search':(300,300),'banner_gold':(240,420),'cat_chip':(200,580),'coupon':(200,640),'addbtn':(225,1092),'dealbar':(400,880),'navpill':(320,940),'navactive':(200,942)})
p('categories.png', {'card':(125,590),'cardbg2':(170,700),'activeTabLine':(130,360),'freebox':(120,380),'sortbar':(120,495)})
p('checkout.png', {'card':(120,800),'card2':(300,1000),'payBtn':(300,1731),'greenSave':(300,1366)})
p('pdetail.png', {'addcart':(110,1593),'buynow':(300,1593),'offer':(120,1527),'delivery':(120,1310)})
p('plist.png', {'card':(110,1000),'addbtn':(140,1050),'chip':(110,861),'discount':(160,1007)})
p('profile.png', {'avatar':(240,620),'card':(120,900),'row':(120,1130)})
