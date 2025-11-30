# R/setup/generate_wiki_faqs.R
files <- list.files("R/setup", pattern = "\\.R$", full.names = FALSE)
base_url <- "https://github.com/JohnGavin/statues_named_john/blob/main/R/setup/"

cat("# Project FAQs: Setup & Maintenance Tasks\n\n", file = "R/setup/WIKI_FAQS_DRAFT.md")

for (f in files) {
  title <- tools::toTitleCase(gsub("_", " ", gsub("\\.R$", "", f)))
  link <- paste0(base_url, f)
  
  cat(paste0("## ", title, "\n\n"), file = "R/setup/WIKI_FAQS_DRAFT.md", append = TRUE)
  cat(paste0("**Script:** `", f, "`\n"), file = "R/setup/WIKI_FAQS_DRAFT.md", append = TRUE)
  cat(paste0("**Link:** [View Source](", link, ")\n\n"), file = "R/setup/WIKI_FAQS_DRAFT.md", append = TRUE)
}

