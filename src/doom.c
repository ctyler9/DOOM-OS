#include <math.h>
#include <ncurses.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int nScreenWidth = 120; // Console Screen Size X (columns)
int nScreenHeight = 40; // Console Screen Size Y (rows)
int nMapWidth = 16;     // World Dimensions
int nMapHeight = 16;

float fPlayerX = 8.0;
float fPlayerY = 8.0;
float fPlayerA = 0.0;

float fFOV = 3.14159 / 4.0;
float fDepth = 16.0;

int main() {
  initscr();   // Initialize ncurses
  noecho();    // Don't echo input
  curs_set(0); // Hide the cursor

  // Create a screen buffer
  wchar_t *screen =
      (wchar_t *)malloc(nScreenWidth * nScreenHeight * sizeof(wchar_t));

  // Your code goes here...
  // Create Map of world space # = wall block, . = space
  // Create a map of world space
  char map[16][16] = {
      "#########.......", "#...............", "#.......########",
      "#..............#", "#......##......#", "#......##......#",
      "#..............#", "###............#", "##.............#",
      "#......####..###", "#......#.......#", "#......#.......#",
      "#..............#", "#......#########", "#..............#",
      "################"};

  time_t tp1, tp2;
  time(&tp1);
  time(&tp2);

  // game loop
  while (1) {

    tp2 = time(NULL);
    double elapsedTime = difftime(tp2, tp1);
    tp1 = tp2;

    float fElapsedTime = (float)elapsedTime;

    if (getch() == 'a') {
      fPlayerA -= (0.1); //* fElapsedTime;
    }

    if (getch() == 'd') {
      fPlayerA += (0.1); // * fElapsedTime;
    }

    if (getch() == 'w') {
      fPlayerX += sinf(fPlayerA) * 5.0; // * fElapsedTime;
      fPlayerY += cosf(fPlayerA) * 5.0; // * fElapsedTime;
    }

    if (getch() == 's') {
      fPlayerX -= sinf(fPlayerA) * 5.0 * fElapsedTime;
      fPlayerY -= cosf(fPlayerA) * 5.0 * fElapsedTime;
    }

    for (int x = 0; x < nScreenWidth; x++) {
      // for each column calculate the projected ray angle into world space
      float fRayAngle =
          (fPlayerA - fFOV / 2.0) + ((float)x / (float)nScreenWidth) * fFOV;

      float fDistanceToWall = 0;
      bool bHitWall = false;

      float fEyeX = sinf(fRayAngle); // Unit vector for ray in player space
      float fEyeY = cosf(fRayAngle);

      while (!bHitWall && fDistanceToWall < fDepth) {
        fDistanceToWall += 0.1;

        int nTestX = (int)(fPlayerX + fEyeX * fDistanceToWall);
        int nTestY = (int)(fPlayerY + fEyeY * fDistanceToWall);

        // test if ray is out of bounds
        if (nTestX < 0 || nTestX >= nMapWidth || nTestY < 0 ||
            nTestY >= nMapHeight) {
          bHitWall = true;
          fDistanceToWall = fDepth;
        } else {
          // ray is inbounds so test to see if the ray cell is a wall block
          if (map[nTestY][nTestX] == '#') {
            bHitWall = true;
          }
        }
      }

      // calculate distance to ceiling and floor
      int nCeiling = (float)(nScreenHeight / 2.0) -
                     nScreenHeight / ((float)fDistanceToWall);
      int nFloor = nScreenHeight - nCeiling;

      // Shader walls based on distance
      char nShade = ' ';
      if (fDistanceToWall <= fDepth / 4.0f)
        // nShade = 0x2588; // Very close
        nShade = '#';
      else if (fDistanceToWall < fDepth / 3.0f)
        // nShade = 0x2593;
        nShade = '&';
      else if (fDistanceToWall < fDepth / 2.0f)
        // nShade = 0x2592;
        nShade = '%';
      else if (fDistanceToWall < fDepth)
        // nShade = 0x2591;
        nShade = '-';
      else
        nShade = ' '; // Too far away

      for (int y = 0; y < nScreenHeight; y++) {
        if (y < nCeiling)
          mvprintw(y, x, " ");
        else if (y > nCeiling && y <= nFloor)
          mvaddch(y, x, nShade);
        // mvprintw(y, x, nShade);
        else
          mvprintw(y, x, " ");
      }
    }
    // Refresh the screen
    refresh();
  }

  // Clean up
  free(screen);
  endwin(); // End ncurses

  return 0;
}
