from PIL import Image
import sys
out=sys.argv[1]; fs=sys.argv[2:]
ims=[Image.open(f).convert('RGB') for f in fs]
w,h=ims[0].size
s=Image.new('RGB',(w*2,h*((len(ims)+1)//2)))
for i,im in enumerate(ims): s.paste(im,((i%2)*w,(i//2)*h))
s.save(out)
