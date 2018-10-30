import os

menu = "0. Quit\n1. Compile\n2. Parse File\n"
os.system("clear; clear;")

while True:
  while True:
    try:
      userinp = input(menu)
      userinp = int(userinp)
      break
    except ValueError:
      os.system("clear; clear;")
      print("{} is Invalid Input".format(userinp))
  if userinp == 0:
    os.system("clear; clear;")
    break
  elif userinp == 1:
    os.system("clear; clear")
    os.system("flex mfpl.l")
    os.system("bison mfpl.y")
    os.system("g++ mfpl.tab.c -o mfpl_eval")
  elif userinp == 2:
    os.system("clear; clear")
    while True:
      userinp = input("fname: ")
      if not os.path.isfile("samp_in/{}.txt".format(userinp)):
        os.system("clear; clear")
        print("File doesn't exist\n")
        continue
      else:
        break
    os.system("mfpl_eval samp_in/{}.txt > out".format(userinp))
    print("------------------------------------------------")
    os.system("mfpl_eval samp_in/{}.txt".format(userinp))
    print("\n------------------------------------------------")
    print("diffing with sample output...")
    os.system("diff out samp_out/{}.txt.out".format(userinp))
    print("Finished diffing\n\n")
    
