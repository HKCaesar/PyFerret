/* Python.h should always be first */
#include <Python.h>
#include <string.h>
#include "grdel.h"
#include "cferbind.h"

/* Instantiate the globals */
const char *CairoCFerBindName = "Cairo";
const int lenCairoCFerBindName = 5;
const char *PyQtCairoCFerBindName = "PyQtCairo";
const int lenPyQtCairoCFerBindName = 9;

/*
 * Creates a CFerBind struct (bindings instance)
 * appropriately assigned for the indicated graphics engine.
 *
 * The currently supported engines are:
 *    "Cairo" - generation of image files only (unmapped) using Cairo
 *    "PyQtCairo" - generate image file using Cairo and display using
 *                  PyQtPipesImager
 *
 * For the "Cairo" engine, the windowname, winnamelen, and
 * visible arguments are ignored as they is not applicable.
 *
 * Returns a pointer to the bindings instance if successful.
 * If an error occurs, grdelerrmsg is assigned an appropriate
 * error message and NULL is returned.
 */
CFerBind *cferbind_createWindow(const char *enginename, int engnamelen,
                                const char *windowname, int winnamelen, int visible)
{
    CFerBind *bindings;
    int k;

    /* Check if the Cairo engine was specified */
    if ( (engnamelen == lenCairoCFerBindName) &&
         (strncmp(enginename, CairoCFerBindName, lenCairoCFerBindName) == 0) ) {
        /* Create a bindings instance for a Cairo engine */
        bindings = cairoCFerBind_createWindow();
        return bindings;
    }

    /* Check if the PyQtCairo engine was specified */
    if ( (engnamelen == lenPyQtCairoCFerBindName) &&
         (strncmp(enginename, PyQtCairoCFerBindName, lenPyQtCairoCFerBindName) == 0) ) {
        /* Create a bindings instance for a PyQtCairo engine */
        bindings = pyqtcairoCFerBind_createWindow(windowname, winnamelen, visible);
        return bindings;
    }

    /* Unknown CFerBind engine */
    strcpy(grdelerrmsg, "Unknown engine: ");
    if (engnamelen < 80)
        k = engnamelen;
    else
        k = 80;
    strncpy(grdelerrmsg + 16, enginename, k);
    grdelerrmsg[k + 16] = '\0';
    return NULL;
}
