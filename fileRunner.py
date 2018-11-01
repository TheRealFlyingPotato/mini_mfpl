import os
import shutil
import filecmp

menu = "0. Quit\n1. Compile\n2. Parse File\n3. Compare all files\n"
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
    os.system("cat samp_in/{}.txt".format(userinp))
    os.system("mfpl_eval samp_in/{}.txt > out".format(userinp))
    print("------------------------------------------------")
    os.system("mfpl_eval samp_in/{}.txt".format(userinp))
    print("\n------------------------------------------------")
    print("diffing with sample output...")
    os.system("diff out samp_out/{}.txt.out".format(userinp))
    print("Finished diffing\n\n")
  elif userinp == 3:
    try:
      shutil.rmtree("my_outs/")
    except:
      pass
    os.makedirs("my_outs/")    
    mypath = os.getcwd() + "/samp_in/"
    inputFiles = [f for f in os.listdir(mypath) if os.path.isfile(os.path.join(mypath, f))]

    failures = list()
    successes = list()

    for f in inputFiles:
      os.system("mfpl_eval samp_in/{} > out".format(f))
      if not filecmp.cmp("samp_out/{}.out".format(f), "out"):
        failures.append(f)
        shutil.copyfile("out", "my_outs/{}_out".format(f))
      else:
        successes.append(f)

    print("----- FAILURES: {} -----".format(len(failures)))
    for f in failures:
      print('\t' + f)

    print("----- SUCCESSES: {} -----".format(len(successes)))
    for f in successes:
      print('\t' + f)
