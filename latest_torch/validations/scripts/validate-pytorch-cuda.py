import torch

print("Cuda is built: {}".format(torch.backends.cuda.is_built()))
print("Cudnn version {}".format(torch.backends.cudnn.version()))
print("Cudnn is available: {}".format(torch.backends.cudnn.is_available()))