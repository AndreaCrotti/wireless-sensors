/**
 * @file   Storage.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Thu Jun  3 16:55:32 2010
 * 
 * @brief  Storage functions to export
 * 
 */

interface Storage {
    // maybe should it be asynchronous?
    command logentry_t getLastLogEntry();
}