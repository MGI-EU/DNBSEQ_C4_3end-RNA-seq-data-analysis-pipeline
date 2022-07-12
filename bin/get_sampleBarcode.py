import json
import sys

def main(input_barcode_config,output_dir):
    output_file = open("%s/barcode_white_list.txt"%output_dir, "a+")
    with open(input_barcode_config,'r') as load_f:
        barcode_dict = json.load(load_f)
        barcode_list = barcode_dict["cell barcode"][0]["white list"]
        for barcode in barcode_list:
            print(barcode + "-1", file=output_file)
    load_f.close()
    output_file.close()

main(input_barcode_config=sys.argv[1], output_dir=sys.argv[2])
