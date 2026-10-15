#Purge implicites rules 
.SUFFIXES:
.SUFFIXES: .html .qmd

# Tools 
QUARTO = quarto



index.html : index.qmd nirea.scss 
	$(QUARTO) preview index.qmd 
clean :
	@rm -fr index_files
