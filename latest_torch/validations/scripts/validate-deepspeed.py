import deepspeed
import pkg_resources
import apex
import transformers
import allennlp
import allennlp.models
import allennlp.modules

print("Deepspeed version {}".format(pkg_resources.get_distribution('deepspeed').version))
print("Apex version {}".format(pkg_resources.get_distribution('apex').version))
print("AllenNLP verison {}".format(allennlp.__version__))