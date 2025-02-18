gcloud composer environments run \
    ut-udot-2-9-composer-dev \
    --location us-central1 \
    connections add \
    -- google_cloud_gisdata_snbx \
    --conn-description "Cross project access" \
    --conn-uri "google-cloud-platform:///?__extra__=%7B%22project%22%3A+%22ut-udot-gisdatasnbx-dev%22%2C+%22num_retries%22%3A+5%7D"\
&& \
gcloud composer environments run \
    ut-udot-2-9-composer-dev \
    --location us-central1 \
    connections add \
    -- google_cloud_toc_da_etl \
    --conn-description "Cross project access" \
    --conn-uri "google-cloud-platform:///?__extra__=%7B%22project%22%3A+%22ut-udot-toc-da-etl-dev%22%2C+%22num_retries%22%3A+5%7D"