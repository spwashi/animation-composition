from os.path import join


def process_logfile(text, alt_logfile):
    out = []
    prev = 0
    lines = map(
        lambda line: int(line.split(": ")[0]),
        filter(None, text.split("\n")),
    )
    for number in lines:
        if not prev:
            prev = number
            continue
        difference = number - prev
        prev = number
        out.append(difference)
    total_minutes = (sum(out) / 1000) / 60
    print(out)
    print(str(total_minutes) + ' minutes')
    alt_logfile.write('\n-\n')
    for i in out:
        alt_logfile.write(str(i) + "\n")
    alt_logfile.write('\n===\n')
    alt_logfile.write(str(total_minutes) + ' minutes' + '\n')
