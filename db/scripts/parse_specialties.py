"""Generate specialties.csv and INSERT SQL command from specialties.txt"""


def main():
    txt_path = r'../database/example_data/src/specialties.txt'
    csv_path = r'../database/example_data/src/specialties.csv'

    # Parse source.
    out_csv = 'code,name\n'
    with open(txt_path, 'r', encoding='utf-8') as f:
        for line in f:
            line_split = line.strip().split()
            code = line_split[0]
            name = ' '.join(line_split[1:-1])
            out_csv += f'{code};"{name}"\n'

    # Generate CSV.
    with open(csv_path, 'w+', encoding='utf-8') as f:
        f.write(out_csv)
    print(f'Created: {csv_path}')

    # Generate SQL INSERT command.
    if not out_csv:
        return
    values = []
    for line in out_csv.split('\n')[1:-1]:
        code, name = line.split(';')
        values.append(f'\t("{code}", {name})'.replace('"', '\''))
    sql = (
        f'INSERT INTO specialty'
        f'\n\t(specialty_code, specialty_name)'
        f'\nVALUES\n'
        f'{",\n".join(values)};'
    )
    print(sql)


if __name__ == '__main__':
    main()
