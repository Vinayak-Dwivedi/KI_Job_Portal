import jsPDF from "jspdf"
import autoTable from "jspdf-autotable"
import Papa from "papaparse"

/**
 * Utility to export data to a premium PDF report
 * @param title - Header title for the PDF
 * @param columns - Array of column definitions { header: string, dataKey: string }
 * @param data - Array of objects containing the data
 * @param filename - Name of the file to save
 */
export const exportToPDF = (
  title: string,
  columns: { header: string; dataKey: string }[],
  data: any[],
  filename: string = "report.pdf"
) => {
  const doc = new jsPDF()
  
  // Set branding/header
  doc.setFontSize(20)
  doc.setTextColor(40)
  doc.text("KI JOB PORTAL - ADMIN SYSTEM", 14, 22)
  
  doc.setFontSize(11)
  doc.setTextColor(100)
  doc.text(`Report: ${title}`, 14, 30)
  doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 36)
  
  // Create table
  autoTable(doc, {
    startY: 45,
    columns: columns,
    body: data,
    theme: 'grid',
    headStyles: {
      fillColor: [63, 81, 181], // Primary blue matching your theme
      textColor: [255, 255, 255],
      fontSize: 10,
      fontStyle: 'bold'
    },
    bodyStyles: {
      fontSize: 9,
      textColor: [33, 33, 33]
    },
    alternateRowStyles: {
      fillColor: [245, 245, 245]
    },
    margin: { top: 40 },
  })
  
  // Save PDF
  doc.save(filename)
}



/**
 * Utility to export data to a CSV file
 * @param data - Array of objects containing the data
 * @param filename - Name of the file to save
 */
export const exportToCSV = (data: any[], filename: string = "report.csv") => {
  const csv = Papa.unparse(data);
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const link = document.createElement("a");
  if (link.download !== undefined) {
    const url = URL.createObjectURL(blob);
    link.setAttribute("href", url);
    link.setAttribute("download", filename);
    link.style.visibility = "hidden";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
}
