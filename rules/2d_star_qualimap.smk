
#############################################
## QC on STAR outputs
#############################################

## qualimap on deduplicated/aligned reads
rule qualimapQC:
    input:
        SORTEDBAM = '{OUTDIR}/{sample}/STARsolo/Aligned.sortedByCoord.dedup.out.bam'
    output:
        qualimapDir = directory('{OUTDIR}/{sample}/qualimap'),
        qualimapReport_txt = '{OUTDIR}/{sample}/qualimap/rnaseq_qc_results.txt',
        qualimapReport_html = '{OUTDIR}/{sample}/qualimap/qualimapReport.html'
    params:
        GENES_GTF = lambda wildcards: GTF_DICT[wildcards.sample]
    threads:
        1
    run:
        shell(
            f"""
            mkdir -p {output.qualimapDir}
            cd {output.qualimapDir}

            {EXEC['QUALIMAP']} rnaseq \
            -bam {input.SORTEDBAM} \
            -gtf {params.GENES_GTF} \
            --sequencing-protocol strand-specific-forward \
            --sorted \
            --java-mem-size=8G \
            -outdir {output.qualimapDir} \
            -outformat html
            """ 
        )
        # -nt {threads} \


rule qualimap_summary2csv:
    input:
        qualimapReport_txt = '{OUTDIR}/{sample}/qualimap/rnaseq_qc_results.txt'
    output:
        qualimapReport_csv = '{OUTDIR}/{sample}/qualimap/rnaseq_qc_result.csv'
    threads:
        1
    run:
        with open(input.qualimapReport_txt, 'r') as file:
            lines = file.readlines()

        out_dict = {}
        for line in lines:
            if '=' in line:
                key, value = line.split('=')
                if '(' in value:
                    value, tmp = value.split('(')
                    value = float(value.strip().replace(',',''))
                elif '%' in value:
                    value = float(value.rstrip('%').strip().replace(',',''))
                elif ',' in value:
                    value = float(value.strip().replace(',',''))
            #TODO - "Junction analysis" section
            # if ':' in line:
            #     key, value = line.split(':')
                out_dict[key.strip()]=value

        # df = pd.json_normalize(sections)
        # print(out_dict)
        out_df = pd.DataFrame.from_dict(
            out_dict, 
            orient='index'
        ) 
        out_df.T.to_csv(
            output.qualimapReport_csv, 
            index=False
        )
