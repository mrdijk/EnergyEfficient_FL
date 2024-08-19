from AD import main as AD_main

def main():
    """
    Main function to analyse the energy data. Make sure that the data-collection 
    is done before running this file. This code assumes that a file for the energy data is present.
    """
    # Perform anomaly detection
    AD_main()

    # TODO: RCA algorithm (output to file also)

if __name__ == '__main__':
    main()