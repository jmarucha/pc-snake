print("JASC-PAL")
print("0100")
print("256")

with open("palette.raw", "rb") as file:
    while rgb := file.read(3):
        r,g,b = [i * 4 + i // 16 for i in rgb]
        print(r, g, b)
