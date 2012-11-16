WickedPdf.config = {
    :wkhtmltopdf => '/usr/local/bin/wkhtmltopdf',
    :layout => "pdf.html",
    :margin => {    :top=> 25,
                    :bottom => 10,
                    :left=> 5,
                    :right => 5},
    :header => {:html => { :template=> 'layouts/pdf_header.html'}},
    :footer => {:html => { :template=> 'layouts/pdf_footer.html'}},
    #:exe_path => '/usr/local/bin/wkhtmltopdf'
}
