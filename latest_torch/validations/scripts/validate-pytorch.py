import torch

def module_exists(module_name):
    try:
        __import__(module_name)
    except ImportError:
        return False
    else:
        return True

print("PyTorch version {}".format(torch.__version__))

if module_exists('torchvision'):
    import torchvision
    print("torchvision version {}".format(torchvision.__version__))
